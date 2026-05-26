#!/usr/bin/env python3
# pip install igraph matplotlib pyvis

import argparse
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

    net.save_graph(path)
    _inject_filters(path, node_meta, edge_scores, max_degree)
    print(f'Saved {path}')


def _inject_filters(path, node_meta, edge_scores, max_degree):
    panel_html = (
        '<div id="filter-panel" style="'
        'position:fixed;top:10px;left:10px;z-index:1000;'
        'background:rgba(15,15,30,0.93);color:#ccc;'
        'border:1px solid #555;border-radius:8px;'
        'padding:14px 18px;font-family:monospace;font-size:13px;'
        'min-width:210px;line-height:1.7;">'
        '<div style="font-weight:bold;margin-bottom:8px;color:#fff;font-size:14px;">Filters</div>'
        '<div style="margin-bottom:8px;">'
        'Min degree: <b id="deg-val">0</b><br>'
        f'<input type="range" id="min-deg" min="0" max="{max_degree}" value="0" style="width:100%">'
        '</div>'
        '<div style="margin-bottom:8px;">'
        'Min edge score: <b id="score-val">0.00</b><br>'
        '<input type="range" id="min-score" min="0" max="100" value="0" style="width:100%">'
        '</div>'
        '<div style="color:#888;margin-bottom:2px;">Roles</div>'
        '<label style="display:block"><input type="checkbox" class="role-cb" value="repeater" checked> Repeaters</label>'
        '<label style="display:block"><input type="checkbox" class="role-cb" value="companion" checked> Companions</label>'
        '<label style="display:block"><input type="checkbox" class="role-cb" value="room" checked> Rooms</label>'
        '<label style="display:block"><input type="checkbox" class="role-cb" value="observer" checked> Observers</label>'
        '<hr style="border-color:#444;margin:8px 0">'
        '<label style="display:block"><input type="checkbox" id="main-only"> Main component only</label>'
        '</div>'
    )

    filter_js = (
        '<script>\n'
        'var NODE_META = ' + json.dumps(node_meta) + ';\n'
        'var EDGE_SCORES = ' + json.dumps(edge_scores) + ';\n'
        r"""
(function() {
  // allNodes/allEdges live here so both the freeze handler and the filter
  // functions share the same reference.
  var allNodes = null;
  var allEdges = null;
  var pendingPositions = null;  // set if stabilization finishes before ready()

  function patchPositions(positions) {
    allNodes = allNodes.map(function(n) {
      var p = positions[n.id];
      if (p) { n.x = p.x; n.y = p.y; }
      return n;
    });
  }

  // Register stabilization listener as soon as vis.js network exists.
  var _freezePoll = setInterval(function() {
    if (typeof network !== 'undefined' && network) {
      clearInterval(_freezePoll);
      network.on('stabilizationIterationsDone', function() {
        network.setOptions({physics: {enabled: false}});
        var positions = network.getPositions();
        if (allNodes) {
          patchPositions(positions);
        } else {
          pendingPositions = positions;  // ready() will apply it
        }
      });
    }
  }, 10);

  function ready(fn) {
    if (document.readyState !== 'loading') fn();
    else document.addEventListener('DOMContentLoaded', fn);
  }

  ready(function() {
    allNodes = nodes.get();
    allEdges = edges.get();
    if (pendingPositions) {
      patchPositions(pendingPositions);
      pendingPositions = null;
    }

    function applyFilters() {
      var minDeg   = parseInt(document.getElementById('min-deg').value);
      var minScore = parseInt(document.getElementById('min-score').value) / 100;
      var mainOnly = document.getElementById('main-only').checked;
      var activeRoles = new Set(
        Array.from(document.querySelectorAll('.role-cb:checked')).map(function(cb) { return cb.value; })
      );

      var visibleIds = new Set();
      var filteredNodes = allNodes.filter(function(n) {
        var m = NODE_META[n.id];
        if (!m) return true;
        if (m.degree < minDeg) return false;
        if (!activeRoles.has(m.role)) return false;
        if (mainOnly && !m.main) return false;
        visibleIds.add(n.id);
        return true;
      });

      var filteredEdges = allEdges.filter(function(e) {
        if (!visibleIds.has(e.from) || !visibleIds.has(e.to)) return false;
        var key = Math.min(e.from, e.to) + '_' + Math.max(e.from, e.to);
        if ((EDGE_SCORES[key] || 0) < minScore) return false;
        return true;
      });

      nodes.clear(); nodes.add(filteredNodes);
      edges.clear(); edges.add(filteredEdges);
    }

    document.getElementById('min-deg').addEventListener('input', function() {
      document.getElementById('deg-val').textContent = this.value;
      applyFilters();
    });
    document.getElementById('min-score').addEventListener('input', function() {
      document.getElementById('score-val').textContent = (this.value / 100).toFixed(2);
      applyFilters();
    });
    document.querySelectorAll('.role-cb').forEach(function(cb) {
      cb.addEventListener('change', applyFilters);
    });
    document.getElementById('main-only').addEventListener('change', applyFilters);
  });
})();
</script>
"""
    )

    with open(path) as f:
        html = f.read()
    html = html.replace('</body>', panel_html + filter_js + '\n</body>')
    with open(path, 'w') as f:
        f.write(html)


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
