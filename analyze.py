#!/usr/bin/env python3
# pip install igraph matplotlib pyvis

import argparse
from html import escape as _escape
import json
import sys
import urllib.request
import igraph as ig
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from pyvis.network import Network

API_URL = 'https://analyzer.00id.net/api/analytics/neighbor-graph'

ROLE_COLORS = {
    'repeater':  '#4e9af1',
    'companion': '#4caf50',
    'room':      '#ff9800',
    'observer':  '#e91e63',
}


def fetch_data(save_path=None):
    print(f'Fetching {API_URL} ...', file=sys.stderr)
    with urllib.request.urlopen(API_URL) as resp:
        raw = resp.read()
    data = json.loads(raw)
    if save_path:
        with open(save_path, 'wb') as f:
            f.write(raw)
        print(f'Saved raw JSON to {save_path}', file=sys.stderr)
    return data


def load_graph(path=None, data=None):
    if data is None:
        with open(path) as f:
            data = json.load(f)

    nodes = data['nodes']
    edges = data['edges']
    pubkey_to_idx = {n['pubkey']: i for i, n in enumerate(nodes)}

    g = ig.Graph()
    g.add_vertices(len(nodes))
    g.vs['pubkey']         = [n['pubkey']        for n in nodes]
    g.vs['name']           = [n['name']           for n in nodes]
    g.vs['role']           = [n['role']           for n in nodes]
    g.vs['neighbor_count'] = [n['neighbor_count'] for n in nodes]

    valid, skipped = [], 0
    edge_keys = ('weight', 'score', 'avg_snr', 'bidirectional', 'ambiguous')
    attrs = {k: [] for k in edge_keys}
    for e in edges:
        src = pubkey_to_idx.get(e['source'])
        tgt = pubkey_to_idx.get(e['target'])
        if src is None or tgt is None:
            skipped += 1
            continue
        valid.append((src, tgt))
        for k in edge_keys:
            attrs[k].append(e.get(k))

    g.add_edges(valid)
    for k, vals in attrs.items():
        g.es[k] = vals

    return g, skipped


def compute_metrics(g):
    g.vs['degree']      = g.degree()
    g.vs['betweenness'] = g.betweenness(weights=None)
    communities         = g.community_multilevel(weights='score')
    g.vs['community']   = communities.membership
    return communities


def print_summary(g, communities, skipped):
    comps = g.connected_components()
    print('=== MeshCore Neighbor Graph ===')
    print(f'Nodes:               {g.vcount()}')
    print(f'Edges:               {g.ecount()}  (skipped {skipped} ambiguous)')
    print(f'Connected components: {len(comps)}  (largest: {max(len(c) for c in comps)} nodes)')
    print(f'Communities (Louvain): {len(communities)}')
    weak = sum(1 for s in g.es['score'] if s < 0.25)
    print(f'Weak links (score<0.25): {weak} / {g.ecount()}')

    print('\nTop 10 nodes by betweenness:')
    top = sorted(g.vs, key=lambda v: v['betweenness'], reverse=True)[:10]
    for v in top:
        print(f'  {v["name"]:<40s} {v["role"]:<10s} deg={v["degree"]:3d}  btwn={v["betweenness"]:.0f}')

    print('\nCommunity sizes (top 10):')
    for i, size in enumerate(sorted(communities.sizes(), reverse=True)[:10]):
        print(f'  #{i}: {size} nodes')


def save_static(g, path):
    degree = g.vs['degree']
    scores = [x for x in g.es['score']   if x is not None]
    snr    = [x for x in g.es['avg_snr'] if x is not None]

    role_counts = {}
    for v in g.vs:
        role_counts[v['role']] = role_counts.get(v['role'], 0) + 1

    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('MeshCore Neighbor Graph Analysis', fontsize=15, fontweight='bold')

    ax = axes[0, 0]
    ax.hist(degree, bins=40, color='steelblue', edgecolor='white', linewidth=0.4)
    ax.set_xlabel('Degree')
    ax.set_ylabel('Frequency (log scale)')
    ax.set_title('Degree Distribution')
    ax.set_yscale('log')

    ax = axes[0, 1]
    ax.hist(scores, bins=40, color='darkorange', edgecolor='white', linewidth=0.4)
    ax.axvline(0.25, color='red', linestyle='--', linewidth=1, label='Weak threshold (0.25)')
    ax.set_xlabel('Link Score')
    ax.set_ylabel('Frequency')
    ax.set_title('Link Quality Score Distribution')
    ax.legend()

    ax = axes[1, 0]
    ax.hist(snr, bins=40, color='mediumpurple', edgecolor='white', linewidth=0.4)
    ax.set_xlabel('Average SNR (dB)')
    ax.set_ylabel('Frequency')
    ax.set_title('Average SNR Distribution')

    ax = axes[1, 1]
    roles  = list(role_counts)
    counts = [role_counts[r] for r in roles]
    colors = [ROLE_COLORS.get(r, '#999') for r in roles]
    bars   = ax.bar(roles, counts, color=colors, edgecolor='white')
    ax.set_xlabel('Role')
    ax.set_ylabel('Count')
    ax.set_title('Node Role Distribution')
    for bar, count in zip(bars, counts):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 5,
                str(count), ha='center', fontsize=10)

    plt.tight_layout()
    plt.savefig(path, dpi=150)
    plt.close()
    print(f'Saved {path}')


def save_interactive(g, path):
    comps     = g.connected_components()
    main_comp = set(max(comps, key=len))

    membership = g.vs['community']
    layout_weights = [
        e['score'] * (5.0 if membership[e.source] == membership[e.target] else 0.5)
        for e in g.es
    ]
    layout = g.layout_drl(weights=layout_weights)

    xs = [pos[0] for pos in layout]
    ys = [pos[1] for pos in layout]
    x_min, x_max = min(xs), max(xs)
    y_min, y_max = min(ys), max(ys)
    spread = 6000

    def scale(v, lo, hi):
        return (v - lo) / (hi - lo) * spread - spread / 2

    net = Network(height='100vh', width='100%', bgcolor='#1a1a2e', font_color='white')

    max_degree = max(g.vs['degree']) or 1
    node_meta  = {}
    for v in g.vs:
        size  = 5 + 30 * (v['degree'] / max_degree)
        title = (
            f"<b>{v['name']}</b><br>"
            f"Role: {v['role']}<br>"
            f"Degree: {v['degree']}<br>"
            f"Neighbor count (API): {v['neighbor_count']}<br>"
            f"Betweenness: {v['betweenness']:.0f}<br>"
            f"Community: {v['community']}"
        )
        net.add_node(
            v.index, label=v['name'], title=title,
            color=ROLE_COLORS.get(v['role'], '#999'), size=size,
            x=scale(xs[v.index], x_min, x_max),
            y=scale(ys[v.index], y_min, y_max),
        )
        node_meta[v.index] = {
            'role':   v['role'],
            'degree': v['degree'],
            'main':   v.index in main_comp,
        }

    edge_scores = {}
    for e in g.es:
        score = e['score']
        r     = int(255 * (1 - score))
        gv    = int(255 * score)
        color = f'rgba({r},{gv},64,0.6)'
        snr_str = f"{e['avg_snr']:.1f}" if e['avg_snr'] is not None else 'n/a'
        net.add_edge(
            e.source, e.target,
            title=f"Score: {score:.3f}<br>SNR: {snr_str} dB<br>Weight: {e['weight']}",
            color=color,
            width=1 + 2 * score,
        )
        key = f'{min(e.source, e.target)}_{max(e.source, e.target)}'
        edge_scores[key] = round(score, 4)

    net.set_options("""{
      "nodes": {"font": {"size": 10}},
      "edges": {"smooth": {"enabled": false}},
      "physics": {
        "enabled": true,
        "barnesHut": {
          "gravitationalConstant": -3000,
          "centralGravity": 0.0,
          "springLength": 80,
          "springConstant": 0.03,
          "damping": 0.9,
          "avoidOverlap": 1.0
        },
        "stabilization": {
          "enabled": true,
          "iterations": 1000,
          "fit": false
        }
      }
    }""")

    node_names = sorted(v['name'] for v in g.vs)
    net.save_graph(path)
    _inject_filters(path, node_meta, edge_scores, max_degree, node_names)
    print(f'Saved {path}')


def _inject_filters(path, node_meta, edge_scores, max_degree, node_names):
    datalist_opts = '\n'.join(f'<option value="{_escape(n)}">' for n in node_names)
    inp_style = 'width:100%;background:#1a1a2e;color:#eee;border:1px solid #555;padding:3px 5px;border-radius:3px;box-sizing:border-box;'
    btn_style = 'background:#2a3a5a;color:#ddd;border:1px solid #555;border-radius:3px;padding:2px 8px;cursor:pointer;'

    panel_html = (
        # shared datalists
        f'<datalist id="node-dl">{datalist_opts}</datalist>'

        '<div id="fp" style="'
        'position:fixed;top:10px;left:10px;z-index:1000;'
        'background:rgba(12,12,28,0.95);color:#ccc;'
        'border:1px solid #556;border-radius:8px;'
        'padding:12px 16px;font-family:monospace;font-size:12px;'
        'min-width:240px;max-height:90vh;overflow-y:auto;line-height:1.6;">'

        # ── Filters ──────────────────────────────────────────
        '<details open><summary style="cursor:pointer;color:#8af;font-weight:bold;margin-bottom:4px;">▸ Filters</summary>'
        f'Min degree: <b id="deg-val">0</b><br><input type="range" id="min-deg" min="0" max="{max_degree}" value="0" style="width:100%">'
        '<br>Min edge score: <b id="score-val">0.00</b><br><input type="range" id="min-score" min="0" max="100" value="0" style="width:100%">'
        '<br><div style="color:#888;margin-top:4px;">Roles</div>'
        '<label><input type="checkbox" class="role-cb" value="repeater" checked> Repeaters</label><br>'
        '<label><input type="checkbox" class="role-cb" value="companion" checked> Companions</label><br>'
        '<label><input type="checkbox" class="role-cb" value="room" checked> Rooms</label><br>'
        '<label><input type="checkbox" class="role-cb" value="observer" checked> Observers</label><br>'
        '<hr style="border-color:#334;margin:6px 0">'
        '<label><input type="checkbox" id="main-only"> Main component only</label>'
        '</details>'

        # ── Neighborhood ─────────────────────────────────────
        '<details style="margin-top:8px;"><summary style="cursor:pointer;color:#8af;font-weight:bold;margin-bottom:4px;">▸ Neighborhood</summary>'
        f'<input id="nb-node" list="node-dl" placeholder="Node name…" style="{inp_style}"><br>'
        '<div style="margin-top:4px;">'
        f'Hops: <button id="nb-minus" style="{btn_style}">−</button> '
        '<b id="nb-hops">1</b> '
        f'<button id="nb-plus" style="{btn_style}">+</button>'
        '</div>'
        '<div style="margin-top:6px;">'
        f'<button id="nb-focus" style="{btn_style}margin-right:6px;">Focus</button>'
        f'<button id="nb-reset" style="{btn_style}">Reset</button>'
        '</div>'
        '</details>'

        # ── Shortest Path ────────────────────────────────────
        '<details style="margin-top:8px;"><summary style="cursor:pointer;color:#8af;font-weight:bold;margin-bottom:4px;">▸ Shortest Path</summary>'
        '<div style="color:#777;font-size:11px;margin-bottom:4px;">Click two nodes, or type names.</div>'
        f'<input id="path-a" list="node-dl" placeholder="From…" style="{inp_style}margin-bottom:4px;">'
        f'<input id="path-b" list="node-dl" placeholder="To…"   style="{inp_style}">'
        '<div style="margin-top:4px;">'
        '<label><input type="checkbox" id="path-repeaters-only" checked> Repeaters only (exclude observers, companions, rooms)</label>'
        '</div>'
        '<div style="margin-top:6px;">'
        f'<button id="path-find" style="{btn_style}margin-right:6px;">Find Path</button>'
        f'<button id="path-reset" style="{btn_style}">Reset</button>'
        '</div>'
        '<div id="path-result" style="margin-top:8px;font-size:11px;color:#adf;line-height:1.5;"></div>'
        '</details>'

        '</div>'
    )

    filter_js = (
        '<script>\n'
        'var NODE_META   = ' + json.dumps(node_meta)   + ';\n'
        'var EDGE_SCORES = ' + json.dumps(edge_scores) + ';\n'
        r"""
(function() {
  var allNodes         = null;
  var allEdges         = null;
  var adj              = {};   // adjacency list built once from allEdges
  var pendingPositions = null;
  var nameToId         = {};
  var idToName         = {};

  function patchPositions(pos) {
    allNodes = allNodes.map(function(n) {
      var p = pos[n.id]; if (p) { n.x = p.x; n.y = p.y; } return n;
    });
  }

  // ── freeze after overlap resolution, wire up click-to-select ──
  var _poll = setInterval(function() {
    if (typeof network === 'undefined' || !network) return;
    clearInterval(_poll);

    network.on('stabilizationIterationsDone', function() {
      network.setOptions({physics: {enabled: false}});
      var pos = network.getPositions();
      if (allNodes) { patchPositions(pos); } else { pendingPositions = pos; }
    });

    // Click node → fill path-a then path-b and auto-run
    network.on('click', function(params) {
      if (!params.nodes.length) return;
      var name = idToName[params.nodes[0]]; if (!name) return;
      var a = document.getElementById('path-a');
      var b = document.getElementById('path-b');
      if (!a.value)                   { a.value = name; }
      else if (!b.value && a.value !== name) { b.value = name; document.getElementById('path-find').click(); }
    });
  }, 10);

  function ready(fn) {
    if (document.readyState !== 'loading') fn(); else document.addEventListener('DOMContentLoaded', fn);
  }

  ready(function() {
    allNodes = nodes.get();
    allEdges = edges.get();
    if (pendingPositions) { patchPositions(pendingPositions); pendingPositions = null; }

    // build name lookups and adjacency list once
    allNodes.forEach(function(n) { nameToId[n.label.toLowerCase()] = n.id; idToName[n.id] = n.label; });
    allEdges.forEach(function(e) {
      if (!adj[e.from]) adj[e.from] = []; if (!adj[e.to]) adj[e.to] = [];
      adj[e.from].push(e.to); adj[e.to].push(e.from);
    });

    function resolveNode(q) {
      q = q.trim().toLowerCase();
      if (nameToId[q] !== undefined) return nameToId[q];
      for (var k in nameToId) { if (k.indexOf(q) !== -1) return nameToId[k]; }
    }

    // ── FILTERS ───────────────────────────────────────────────────────
    function applyFilters() {
      var minDeg   = parseInt(document.getElementById('min-deg').value);
      var minScore = parseInt(document.getElementById('min-score').value) / 100;
      var mainOnly = document.getElementById('main-only').checked;
      var roles    = new Set(Array.from(document.querySelectorAll('.role-cb:checked')).map(function(c) { return c.value; }));
      var vis = new Set();
      var fn = allNodes.filter(function(n) {
        var m = NODE_META[n.id]; if (!m) return true;
        if (m.degree < minDeg || !roles.has(m.role) || (mainOnly && !m.main)) return false;
        vis.add(n.id); return true;
      });
      var fe = allEdges.filter(function(e) {
        if (!vis.has(e.from) || !vis.has(e.to)) return false;
        return (EDGE_SCORES[Math.min(e.from,e.to)+'_'+Math.max(e.from,e.to)] || 0) >= minScore;
      });
      nodes.clear(); nodes.add(fn); edges.clear(); edges.add(fe);
    }
    document.getElementById('min-deg').addEventListener('input', function() {
      document.getElementById('deg-val').textContent = this.value; applyFilters();
    });
    document.getElementById('min-score').addEventListener('input', function() {
      document.getElementById('score-val').textContent = (this.value/100).toFixed(2); applyFilters();
    });
    document.querySelectorAll('.role-cb').forEach(function(cb) { cb.addEventListener('change', applyFilters); });
    document.getElementById('main-only').addEventListener('change', applyFilters);

    // ── NEIGHBORHOOD ─────────────────────────────────────────────────
    var nbHops = 1;
    var nbFocal = null;

    function applyNeighborhood() {
      if (nbFocal === null) return;
      var visited = new Set([nbFocal]);
      var frontier = [nbFocal];
      for (var h = 0; h < nbHops; h++) {
        var next = [];
        frontier.forEach(function(id) {
          (adj[id] || []).forEach(function(nb) { if (!visited.has(nb)) { visited.add(nb); next.push(nb); } });
        });
        frontier = next;
      }
      var fn = allNodes.filter(function(n) { return visited.has(n.id); }).map(function(n) {
        return n.id === nbFocal ? Object.assign({}, n, {color: '#ffffff', borderWidth: 3}) : n;
      });
      var fe = allEdges.filter(function(e) { return visited.has(e.from) && visited.has(e.to); });
      nodes.clear(); nodes.add(fn); edges.clear(); edges.add(fe);
    }

    document.getElementById('nb-focus').addEventListener('click', function() {
      var id = resolveNode(document.getElementById('nb-node').value);
      if (id === undefined) { alert('Node not found'); return; }
      nbFocal = id; applyNeighborhood();
    });
    document.getElementById('nb-minus').addEventListener('click', function() {
      if (nbHops > 1) { nbHops--; document.getElementById('nb-hops').textContent = nbHops; applyNeighborhood(); }
    });
    document.getElementById('nb-plus').addEventListener('click', function() {
      nbHops++; document.getElementById('nb-hops').textContent = nbHops; applyNeighborhood();
    });
    document.getElementById('nb-reset').addEventListener('click', function() {
      nbFocal = null; nbHops = 1;
      document.getElementById('nb-hops').textContent = '1';
      document.getElementById('nb-node').value = '';
      applyFilters();
    });

    // ── SHORTEST PATH (score-weighted Dijkstra) ───────────────────────
    function dijkstra(src, dst) {
      var repeatersOnly = document.getElementById('path-repeaters-only').checked;
      var dist = {}; dist[src] = 0;
      var prev = {};
      var visited = new Set();
      var queue = [{node: src, cost: 0}];
      while (queue.length) {
        queue.sort(function(a,b) { return a.cost - b.cost; });
        var u = queue.shift();
        if (visited.has(u.node)) continue;
        visited.add(u.node);
        if (u.node === dst) break;
        allEdges.forEach(function(e) {
          var nb = (e.from === u.node) ? e.to : (e.to === u.node) ? e.from : null;
          if (nb === null || visited.has(nb)) return;
          // When repeaters-only, skip non-repeater intermediate nodes (but allow the destination)
          if (repeatersOnly && nb !== dst) {
            var m = NODE_META[nb];
            if (m && m.role !== 'repeater') return;
          }
          var score = EDGE_SCORES[Math.min(u.node,nb)+'_'+Math.max(u.node,nb)] || 0.01;
          var d = dist[u.node] + (1 / score);
          if (dist[nb] === undefined || d < dist[nb]) { dist[nb] = d; prev[nb] = u.node; queue.push({node: nb, cost: d}); }
        });
      }
      if (dist[dst] === undefined) return null;
      var path = []; var cur = dst;
      while (cur !== undefined) { path.unshift(cur); cur = prev[cur]; }
      return path[0] === src ? {nodes: path, cost: dist[dst]} : null;
    }

    function isolatedMsg(id) {
      var m = NODE_META[id];
      if (m && m.degree === 0)
        return (idToName[id] || id) + ' has no connections in this snapshot — all its neighbor links are ambiguous (pubkeys not in node list).';
    }

    document.getElementById('path-find').addEventListener('click', function() {
      var out = document.getElementById('path-result');
      var aId = resolveNode(document.getElementById('path-a').value);
      var bId = resolveNode(document.getElementById('path-b').value);
      if (aId === undefined || bId === undefined) { out.textContent = 'Node not found'; return; }
      if (aId === bId) { out.textContent = 'Same node'; return; }
      var msg = isolatedMsg(aId) || isolatedMsg(bId);
      if (msg) { out.textContent = msg; return; }
      var res = dijkstra(aId, bId);
      if (!res) { out.textContent = 'No path found — nodes may be in disconnected components'; return; }

      var pathSet = new Set(res.nodes);
      var fn = allNodes.filter(function(n) { return pathSet.has(n.id); }).map(function(n) {
        var bg = (n.id === aId || n.id === bId) ? '#ff5555' : '#f0c040';
        return Object.assign({}, n, {color: {background: bg, border: '#fff', highlight: {background: bg, border: '#fff'}}, borderWidth: 3});
      });
      var fe = [];
      for (var i = 0; i < res.nodes.length - 1; i++) {
        var u = res.nodes[i], v = res.nodes[i+1];
        allEdges.forEach(function(e) {
          if ((e.from===u&&e.to===v)||(e.from===v&&e.to===u)) {
            var score = EDGE_SCORES[Math.min(u,v)+'_'+Math.max(u,v)] || 0;
            fe.push(Object.assign({}, e, {color:{color:'#f0c040',opacity:1}, width:4, title:'Score: '+score.toFixed(3)}));
          }
        });
      }
      nodes.clear(); nodes.add(fn); edges.clear(); edges.add(fe);

      var hops = res.nodes.length - 1;
      var avgScore = hops > 0 ? (hops / res.cost).toFixed(3) : '—';
      var names = res.nodes.map(function(id) { return idToName[id] || id; });
      out.innerHTML = '<b>' + hops + ' hop' + (hops!==1?'s':'') + '</b> · avg score: ' + avgScore + '<br><br>' +
        names.map(function(n,i) {
          return '<span style="color:' + (i===0||i===names.length-1?'#ff9090':'#f0c040') + '">' + n + '</span>';
        }).join('<br><span style="color:#666">↓</span><br>');
    });

    document.getElementById('path-reset').addEventListener('click', function() {
      document.getElementById('path-a').value = '';
      document.getElementById('path-b').value = '';
      document.getElementById('path-result').textContent = '';
      applyFilters();
    });
  });
})();
</script>
"""
    )

    with open(path) as f:
        content = f.read()
    content = content.replace('</body>', panel_html + filter_js + '\n</body>')
    with open(path, 'w') as f:
        f.write(content)


def parse_args():
    p = argparse.ArgumentParser(description='Analyze a MeshCore neighbor graph.')
    src = p.add_mutually_exclusive_group()
    src.add_argument('--input',  '-i', metavar='FILE', default='neighbor-graph.json',
                     help='Input JSON file (default: neighbor-graph.json)')
    src.add_argument('--fetch',  '-f', action='store_true',
                     help=f'Fetch latest graph from {API_URL}')
    p.add_argument('--save',  '-s', metavar='FILE', default=None,
                   help='Save fetched JSON to FILE (only used with --fetch)')
    p.add_argument('--pdf',        metavar='FILE', default='neighbor-graph-static.pdf',
                   help='Static PDF output (default: neighbor-graph-static.pdf)')
    p.add_argument('--html',       metavar='FILE', default='neighbor-graph-interactive.html',
                   help='Interactive HTML output (default: neighbor-graph-interactive.html)')
    return p.parse_args()


if __name__ == '__main__':
    args = parse_args()

    if args.fetch:
        data = fetch_data(save_path=args.save)
        g, skipped = load_graph(data=data)
    else:
        g, skipped = load_graph(path=args.input)

    communities = compute_metrics(g)
    print_summary(g, communities, skipped)
    save_static(g, args.pdf)
    save_interactive(g, args.html)
