#!/usr/bin/env python3
# pip install igraph matplotlib

import argparse
from html import escape as _escape
import json
import os
import sys
import urllib.request
import igraph as ig
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

GRAPH_API_URL = 'https://analyzer.00id.net/api/analytics/neighbor-graph'
NODES_API_URL = 'https://analyzer.00id.net/api/nodes?limit=10000'

ROLE_COLORS = {
    'repeater':  '#4e9af1',
    'companion': '#4caf50',
    'room':      '#ff9800',
    'observer':  '#e91e63',
}

# ── static JS embedded in generated HTML ───────────────────────────────────
_LEAFLET_JS = r"""
(function() {
  // ── lookups ──────────────────────────────────────────────────────────────
  var nodeById = {}, nameToId = {}, idToName = {};
  NODES.forEach(function(n) {
    nodeById[n.id] = n;
    nameToId[n.name.toLowerCase()] = n.id;
    idToName[n.id] = n.name;
  });

  var adj = {};
  EDGES.forEach(function(e) {
    if (!adj[e.from]) adj[e.from] = [];
    if (!adj[e.to])   adj[e.to]   = [];
    adj[e.from].push(e);
    adj[e.to].push(e);
  });

  // ── map setup ────────────────────────────────────────────────────────────
  var positioned = NODES.filter(function(n){return n.lat!==null;});
  var cLat = positioned.reduce(function(a,n){return a+n.lat;},0)/positioned.length;
  var cLon = positioned.reduce(function(a,n){return a+n.lon;},0)/positioned.length;

  var map = L.map('map').setView([cLat, cLon], 7);
  L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/attributions">CARTO</a>',
    subdomains: 'abcd',
    maxZoom: 19
  }).addTo(map);

  // ── style helpers ────────────────────────────────────────────────────────
  var ROLE_COLORS = {repeater:'#4e9af1',companion:'#4caf50',room:'#ff9800',observer:'#e91e63'};
  function roleColor(role) { return ROLE_COLORS[role] || '#999'; }
  function scoreRgba(score, alpha) {
    var r=Math.round(255*(1-score)), g=Math.round(255*score);
    return 'rgba('+r+','+g+',64,'+(alpha||0.75)+')';
  }
  var maxDeg = NODES.reduce(function(m,n){return Math.max(m,n.degree);},0)||1;
  function nodeRadius(deg) { return 4+12*(deg/maxDeg); }
  function nodeStyle(n, override) {
    var isReal = n.gps==='real';
    return Object.assign({
      radius:      nodeRadius(n.degree),
      fillColor:   roleColor(n.role),
      color:       isReal ? '#fff' : '#aaa',
      weight:      isReal ? 1.5 : 0.75,
      fillOpacity: isReal ? 0.85 : 0.55
    }, override||{});
  }

  // ── create layers (edges first, nodes on top) ─────────────────────────────
  var edgeGroup = L.layerGroup().addTo(map);
  var nodeGroup = L.layerGroup().addTo(map);
  var edgeMarkers = {}, nodeMarkers = {};

  EDGES.forEach(function(e) {
    var a=nodeById[e.from], b=nodeById[e.to];
    if (a.lat===null||b.lat===null) return; // can't draw edge without positions
    var snr = e.avg_snr!==null ? e.avg_snr.toFixed(1)+' dB' : 'n/a';
    var line = L.polyline([[a.lat,a.lon],[b.lat,b.lon]], {
      color:   scoreRgba(e.score),
      weight:  1+2*e.score,
      opacity: 0.75
    }).bindTooltip('Score: '+e.score.toFixed(3)+'<br>SNR: '+snr, {sticky:true});
    edgeMarkers[e.id] = line;
    edgeGroup.addLayer(line);
  });

  NODES.forEach(function(n) {
    if (n.lat===null||n.lon===null) return; // no position — skip marker
    var gpsNote = n.gps!=='real' ? ' <span style="color:#888">('+n.gps+')</span>' : '';
    var m = L.circleMarker([n.lat,n.lon], nodeStyle(n))
      .bindTooltip(
        '<b>'+n.name+'</b>'+gpsNote+'<br>Role: '+n.role+
        '<br>Degree: '+n.degree+'<br>Betweenness: '+n.betweenness.toFixed(0)+
        '<br>Community: '+n.community,
        {sticky:true}
      );
    m.on('click', function() { handleNodeClick(n.id); });
    nodeMarkers[n.id] = m;
    nodeGroup.addLayer(m);
  });

  // ── helpers ───────────────────────────────────────────────────────────────
  function setNode(n, style) {
    if (!nodeMarkers[n.id]) return;
    nodeMarkers[n.id].setStyle(style);
    nodeMarkers[n.id].setRadius(style.radius||nodeRadius(n.degree));
  }

  function resolveNode(q) {
    q = q.trim().toLowerCase(); if (!q) return undefined;
    if (nameToId[q]!==undefined) return nameToId[q];
    for (var k in nameToId) { if (k.indexOf(q)!==-1) return nameToId[k]; }
    return undefined;
  }

  // ── node click → route to whichever panel is open ────────────────────────
  var lastActive = null;  // 'neighborhood' | 'path'

  function activeTarget() {
    var nbOpen   = document.getElementById('nb-details').open;
    var pathOpen = document.getElementById('path-details').open;
    if (nbOpen && !pathOpen)  return 'neighborhood';
    if (pathOpen && !nbOpen)  return 'path';
    if (nbOpen && pathOpen)   return lastActive || 'neighborhood';
    return null;
  }

  function handleNodeClick(id) {
    var name = idToName[id];
    var target = activeTarget();
    if (target === 'neighborhood') {
      document.getElementById('nb-node').value = name;
      nbFocal = id; applyNeighborhood();
      lastActive = 'neighborhood';
    } else if (target === 'path') {
      var a=document.getElementById('path-a'), b=document.getElementById('path-b');
      if (!a.value) { a.value=name; lastActive='path'; }
      else if (!b.value && a.value!==name) { b.value=name; lastActive='path'; document.getElementById('path-find').click(); }
    }
  }

  // ── filters ───────────────────────────────────────────────────────────────
  function getFilter() {
    var minDeg    = parseInt(document.getElementById('min-deg').value);
    var minScore  = parseInt(document.getElementById('min-score').value)/100;
    var mainOnly  = document.getElementById('main-only').checked;
    var showEst   = document.getElementById('show-estimated').checked;
    var showEdges = document.getElementById('show-edges').checked;
    var roles     = new Set(Array.from(document.querySelectorAll('.role-cb:checked')).map(function(c){return c.value;}));
    return {minDeg:minDeg, minScore:minScore, mainOnly:mainOnly, showEst:showEst, showEdges:showEdges, roles:roles};
  }

  function applyFilters() {
    var f = getFilter();
    nodeGroup.clearLayers(); edgeGroup.clearLayers();
    var vis = new Set();
    NODES.forEach(function(n) {
      if (!nodeMarkers[n.id]) return;
      if (n.degree<f.minDeg || !f.roles.has(n.role) || (f.mainOnly&&!n.main)) return;
      if (!f.showEst && n.gps!=='real') return;
      vis.add(n.id);
      setNode(n, nodeStyle(n));
      nodeGroup.addLayer(nodeMarkers[n.id]);
    });
    if (f.showEdges) {
      EDGES.forEach(function(e) {
        if (!edgeMarkers[e.id]||!vis.has(e.from)||!vis.has(e.to)||e.score<f.minScore) return;
        edgeMarkers[e.id].setStyle({color:scoreRgba(e.score), weight:1+2*e.score, opacity:0.75});
        edgeGroup.addLayer(edgeMarkers[e.id]);
      });
    }
  }

  document.getElementById('min-deg').addEventListener('input', function() {
    document.getElementById('deg-val').textContent=this.value; applyFilters();
  });
  document.getElementById('min-score').addEventListener('input', function() {
    document.getElementById('score-val').textContent=(this.value/100).toFixed(2); applyFilters();
  });
  document.querySelectorAll('.role-cb').forEach(function(cb){cb.addEventListener('change',applyFilters);});
  document.getElementById('main-only').addEventListener('change', applyFilters);
  document.getElementById('show-estimated').addEventListener('change', applyFilters);
  document.getElementById('show-edges').addEventListener('change', applyFilters);

  applyFilters(); // apply initial checkbox state on load

  // ── neighborhood ──────────────────────────────────────────────────────────
  var nbHops=1, nbFocal=null;
  function applyNeighborhood() {
    if (nbFocal===null) return;
    var visited=new Set([nbFocal]), frontier=[nbFocal];
    for (var h=0;h<nbHops;h++) {
      var next=[];
      frontier.forEach(function(id){
        (adj[id]||[]).forEach(function(e){
          var nb=e.from===id?e.to:e.from;
          if (!visited.has(nb)){visited.add(nb);next.push(nb);}
        });
      });
      frontier=next;
    }
    nodeGroup.clearLayers(); edgeGroup.clearLayers();
    NODES.forEach(function(n) {
      if (!nodeMarkers[n.id]||!visited.has(n.id)) return;
      var focal = n.id===nbFocal;
      setNode(n, Object.assign(nodeStyle(n), focal?{fillColor:'#ffffff',color:'#fff',weight:3,radius:nodeRadius(n.degree)+4}:{}));
      nodeGroup.addLayer(nodeMarkers[n.id]);
    });
    EDGES.forEach(function(e) {
      if (!edgeMarkers[e.id]||!visited.has(e.from)||!visited.has(e.to)) return;
      edgeMarkers[e.id].setStyle({color:scoreRgba(e.score), weight:1+2*e.score, opacity:0.85});
      edgeGroup.addLayer(edgeMarkers[e.id]);
    });
  }

  document.getElementById('nb-node').addEventListener('focus', function() { lastActive='neighborhood'; });
  document.getElementById('nb-focus').addEventListener('click', function() {
    lastActive='neighborhood';
    var id=resolveNode(document.getElementById('nb-node').value);
    if (id===undefined){alert('Node not found');return;}
    nbFocal=id; applyNeighborhood();
  });
  document.getElementById('nb-minus').addEventListener('click', function() {
    if (nbHops>1){nbHops--;document.getElementById('nb-hops').textContent=nbHops;applyNeighborhood();}
  });
  document.getElementById('nb-plus').addEventListener('click', function() {
    nbHops++;document.getElementById('nb-hops').textContent=nbHops;applyNeighborhood();
  });
  document.getElementById('nb-reset').addEventListener('click', function() {
    nbFocal=null;nbHops=1;
    document.getElementById('nb-hops').textContent='1';
    document.getElementById('nb-node').value='';
    applyFilters();
  });

  // ── shortest path (score × distance Dijkstra) ─────────────────────────────
  function haversine(la1,lo1,la2,lo2) {
    var R=6371,p=Math.PI/180;
    var dLa=(la2-la1)*p, dLo=(lo2-lo1)*p;
    var a=Math.sin(dLa/2)*Math.sin(dLa/2)+Math.cos(la1*p)*Math.cos(la2*p)*Math.sin(dLo/2)*Math.sin(dLo/2);
    return R*2*Math.atan2(Math.sqrt(a),Math.sqrt(1-a));
  }
  function edgeCost(e,nA,nB) {
    var score=Math.max(e.score||0,0.01);
    var dist=(nA.lat!==null&&nB.lat!==null&&nA.gps==='real'&&nB.gps==='real')
      ? Math.max(haversine(nA.lat,nA.lon,nB.lat,nB.lon),1.0)
      : 50.0;
    return (1/score)*dist;
  }

  function dijkstra(srcId,dstId) {
    var repeatersOnly=document.getElementById('path-repeaters-only').checked;
    var dist={},prev={},visited=new Set();
    dist[srcId]=0;
    var queue=[{node:srcId,cost:0}];
    while (queue.length) {
      queue.sort(function(a,b){return a.cost-b.cost;});
      var u=queue.shift();
      if (visited.has(u.node)) continue;
      visited.add(u.node);
      if (u.node===dstId) break;
      (adj[u.node]||[]).forEach(function(e) {
        var nb=e.from===u.node?e.to:e.from;
        if (visited.has(nb)) return;
        if (repeatersOnly&&nb!==dstId&&nodeById[nb].role!=='repeater') return;
        var cost=dist[u.node]+edgeCost(e,nodeById[u.node],nodeById[nb]);
        if (dist[nb]===undefined||cost<dist[nb]){dist[nb]=cost;prev[nb]=u.node;queue.push({node:nb,cost:cost});}
      });
    }
    if (dist[dstId]===undefined) return null;
    var path=[],cur=dstId;
    while (cur!==undefined){path.unshift(cur);cur=prev[cur];}
    return path[0]===srcId?{nodes:path,cost:dist[dstId]}:null;
  }

  function isolatedMsg(id) {
    var n=nodeById[id];
    return (n&&n.degree===0) ? (n.name+' has no connections — all its neighbor links have ambiguous pubkeys.') : null;
  }

  document.getElementById('path-a').addEventListener('focus', function() { lastActive='path'; });
  document.getElementById('path-b').addEventListener('focus', function() { lastActive='path'; });
  document.getElementById('path-find').addEventListener('click', function() {
    lastActive='path';
    var out=document.getElementById('path-result');
    var aId=resolveNode(document.getElementById('path-a').value);
    var bId=resolveNode(document.getElementById('path-b').value);
    if (aId===undefined||bId===undefined){out.textContent='Node not found';return;}
    if (aId===bId){out.textContent='Same node';return;}
    var msg=isolatedMsg(aId)||isolatedMsg(bId);
    if (msg){out.textContent=msg;return;}
    var res=dijkstra(aId,bId);
    if (!res){out.textContent='No path found — nodes may be in disconnected components';return;}

    var pathSet=new Set(res.nodes);
    nodeGroup.clearLayers(); edgeGroup.clearLayers();
    NODES.forEach(function(n) {
      if (!nodeMarkers[n.id]||!pathSet.has(n.id)) return;
      var isSrc=n.id===aId||n.id===bId;
      setNode(n,{fillColor:isSrc?'#ff5555':'#f0c040',color:'#fff',weight:3,
                 radius:nodeRadius(n.degree)+3,fillOpacity:1.0});
      nodeGroup.addLayer(nodeMarkers[n.id]);
    });

    var totalScore=0, totalDist=0, hops=res.nodes.length-1;
    for (var i=0;i<hops;i++) {
      var u=res.nodes[i],v=res.nodes[i+1];
      EDGES.forEach(function(e) {
        if (!edgeMarkers[e.id]) return;
        if (!((e.from===u&&e.to===v)||(e.from===v&&e.to===u))) return;
        totalScore+=e.score||0;
        var nA=nodeById[u],nB=nodeById[v];
        if (nA.lat!==null&&nB.lat!==null&&nA.gps==='real'&&nB.gps==='real')
          totalDist+=haversine(nA.lat,nA.lon,nB.lat,nB.lon);
        edgeMarkers[e.id].setStyle({color:'#f0c040',weight:4,opacity:1.0});
        edgeGroup.addLayer(edgeMarkers[e.id]);
      });
    }

    var avgScore=hops>0?(totalScore/hops).toFixed(3):'—';
    var distStr=totalDist>0?totalDist.toFixed(0)+' km':'n/a';
    var names=res.nodes.map(function(id){return idToName[id]||id;});
    out.innerHTML='<b>'+hops+' hop'+(hops!==1?'s':'')+'</b> · avg score: '+avgScore+' · '+distStr+'<br><br>'+
      names.map(function(n,i){
        return '<span style="color:'+(i===0||i===names.length-1?'#ff9090':'#f0c040')+'">'+n+'</span>';
      }).join('<br><span style="color:#666">↓</span><br>');
  });

  document.getElementById('path-reset').addEventListener('click', function() {
    document.getElementById('path-a').value='';
    document.getElementById('path-b').value='';
    document.getElementById('path-result').textContent='';
    applyFilters();
  });
})();
"""


def fetch_data(save_path=None):
    print(f'Fetching {GRAPH_API_URL} ...', file=sys.stderr)
    with urllib.request.urlopen(GRAPH_API_URL) as resp:
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
    g.vs['pubkey'] = [n['pubkey'] for n in nodes]
    g.vs['name']   = [n['name']   for n in nodes]
    g.vs['role']   = [n['role']   for n in nodes]

    valid, skipped = [], 0
    edge_keys = ('weight', 'score', 'avg_snr')
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


def fetch_nodes(save_path=None):
    print(f'Fetching {NODES_API_URL} ...', file=sys.stderr)
    with urllib.request.urlopen(NODES_API_URL) as resp:
        raw = resp.read()
    data = json.loads(raw)
    if save_path:
        with open(save_path, 'wb') as f:
            f.write(raw)
        print(f'Saved node data to {save_path}', file=sys.stderr)
    return data


def load_node_locations(path=None, data=None):
    if data is None:
        with open(path) as f:
            data = json.load(f)
    result = {}
    for n in data.get('nodes', []):
        pk  = n.get('public_key')
        lat = n.get('lat')
        lon = n.get('lon')
        if pk and lat is not None and lon is not None and not (lat == 0 and lon == 0):
            result[pk] = (lat, lon)
    return result


def attach_locations(g, loc_by_pubkey):
    lats     = [None] * g.vcount()
    lons     = [None] * g.vcount()
    gps_type = ['unknown'] * g.vcount()

    for v in g.vs:
        loc = loc_by_pubkey.get(v['pubkey'])
        if loc:
            lats[v.index] = loc[0]
            lons[v.index] = loc[1]
            gps_type[v.index] = 'real'

    for _ in range(10):
        changed = False
        for v in g.vs:
            if lats[v.index] is not None:
                continue
            nbs = g.neighbors(v.index)
            nb_lats = [lats[nb] for nb in nbs if lats[nb] is not None]
            nb_lons = [lons[nb] for nb in nbs if lons[nb] is not None]
            if nb_lats:
                lats[v.index] = sum(nb_lats) / len(nb_lats)
                lons[v.index] = sum(nb_lons) / len(nb_lons)
                gps_type[v.index] = 'centroid'
                changed = True
        if not changed:
            break

    g.vs['lat']      = lats
    g.vs['lon']      = lons
    g.vs['gps_type'] = gps_type

    real     = sum(1 for t in gps_type if t == 'real')
    centroid = sum(1 for t in gps_type if t == 'centroid')
    unknown  = sum(1 for t in gps_type if t == 'unknown')
    print(f'Node locations: {real} real GPS, {centroid} centroid estimate, {unknown} unknown (hidden)', file=sys.stderr)


def save_interactive(g, path):
    comps     = g.connected_components()
    main_comp = set(max(comps, key=len))

    nodes_data = [
        {
            'id':          v.index,
            'name':        v['name'],
            'role':        v['role'],
            'lat':         v['lat'],
            'lon':         v['lon'],
            'gps':         v['gps_type'],
            'degree':      v['degree'],
            'betweenness': round(v['betweenness'], 1),
            'community':   v['community'],
            'main':        v.index in main_comp,
        }
        for v in g.vs
    ]

    edges_data = [
        {
            'id':      e.index,
            'from':    e.source,
            'to':      e.target,
            'score':   round(e['score'] or 0, 4),
            'avg_snr': round(e['avg_snr'], 1) if e['avg_snr'] is not None else None,
            'weight':  e['weight'],
        }
        for e in g.es
    ]

    max_degree = max(v['degree'] for v in g.vs) or 1
    node_names = sorted(_escape(v['name']) for v in g.vs)
    datalist_opts = '\n'.join(f'<option value="{n}">' for n in node_names)

    inp = 'width:100%;background:#1a1a2e;color:#eee;border:1px solid #555;padding:3px 5px;border-radius:3px;box-sizing:border-box;'
    btn = 'background:#2a3a5a;color:#ddd;border:1px solid #555;border-radius:3px;padding:2px 8px;cursor:pointer;'

    panel = (
        f'<datalist id="node-dl">{datalist_opts}</datalist>'
        '<div id="fp" style="position:fixed;top:10px;left:10px;z-index:1000;'
        'background:rgba(12,12,28,0.95);color:#ccc;border:1px solid #556;border-radius:8px;'
        'padding:12px 16px;font-family:monospace;font-size:12px;'
        'min-width:240px;max-height:90vh;overflow-y:auto;line-height:1.6;">'

        '<details open><summary style="cursor:pointer;color:#8af;font-weight:bold;margin-bottom:4px;">▸ Filters</summary>'
        f'Min degree: <b id="deg-val">0</b><br>'
        f'<input type="range" id="min-deg" min="0" max="{max_degree}" value="0" style="width:100%">'
        '<br>Min edge score: <b id="score-val">0.00</b><br>'
        '<input type="range" id="min-score" min="0" max="100" value="0" style="width:100%">'
        '<br><div style="color:#888;margin-top:4px;">Roles</div>'
        '<label><input type="checkbox" class="role-cb" value="repeater" checked> Repeaters</label><br>'
        '<label><input type="checkbox" class="role-cb" value="companion" checked> Companions</label><br>'
        '<label><input type="checkbox" class="role-cb" value="room" checked> Rooms</label><br>'
        '<label><input type="checkbox" class="role-cb" value="observer" checked> Observers</label><br>'
        '<hr style="border-color:#334;margin:6px 0">'
        '<label><input type="checkbox" id="main-only"> Main component only</label><br>'
        '<label><input type="checkbox" id="show-estimated" checked> Show position-estimated nodes</label><br>'
        '<label><input type="checkbox" id="show-edges"> Show edges</label>'
        '</details>'

        '<details id="nb-details" style="margin-top:8px;"><summary style="cursor:pointer;color:#8af;font-weight:bold;margin-bottom:4px;">▸ Neighborhood</summary>'
        f'<input id="nb-node" list="node-dl" placeholder="Node name…" style="{inp}"><br>'
        f'<div style="margin-top:4px;">Hops: <button id="nb-minus" style="{btn}">−</button> '
        f'<b id="nb-hops">1</b> <button id="nb-plus" style="{btn}">+</button></div>'
        f'<div style="margin-top:6px;"><button id="nb-focus" style="{btn}margin-right:6px;">Focus</button>'
        f'<button id="nb-reset" style="{btn}">Reset</button></div>'
        '</details>'

        '<details id="path-details" style="margin-top:8px;"><summary style="cursor:pointer;color:#8af;font-weight:bold;margin-bottom:4px;">▸ Shortest Path</summary>'
        '<div style="color:#777;font-size:11px;margin-bottom:4px;">Click two nodes, or type names.</div>'
        f'<input id="path-a" list="node-dl" placeholder="From…" style="{inp}margin-bottom:4px;">'
        f'<input id="path-b" list="node-dl" placeholder="To…"   style="{inp}">'
        '<div style="margin-top:4px;"><label><input type="checkbox" id="path-repeaters-only" checked>'
        ' Repeaters only (exclude observers, companions, rooms)</label></div>'
        f'<div style="margin-top:6px;"><button id="path-find" style="{btn}margin-right:6px;">Find Path</button>'
        f'<button id="path-reset" style="{btn}">Reset</button></div>'
        '<div id="path-result" style="margin-top:8px;font-size:11px;color:#adf;line-height:1.5;"></div>'
        '</details>'

        '</div>'
    )

    html = (
        '<!DOCTYPE html>\n<html>\n<head>\n'
        '<meta charset="utf-8">\n'
        '<title>MeshCore Neighbor Graph</title>\n'
        '<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">\n'
        '<style>body{margin:0;padding:0;}#map{width:100%;height:100vh;}</style>\n'
        '</head>\n<body>\n'
        '<div id="map"></div>\n'
        + panel + '\n'
        '<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>\n'
        '<script>\n'
        'var NODES = ' + json.dumps(nodes_data) + ';\n'
        'var EDGES = ' + json.dumps(edges_data) + ';\n'
        + _LEAFLET_JS +
        '\n</script>\n'
        '</body>\n</html>\n'
    )

    with open(path, 'w') as f:
        f.write(html)
    print(f'Saved {path}')


def parse_args():
    p = argparse.ArgumentParser(description='Analyze a MeshCore neighbor graph.')
    src = p.add_mutually_exclusive_group()
    src.add_argument('--input',  '-i', metavar='FILE', default='neighbor-graph.json',
                     help='Input graph JSON file (default: neighbor-graph.json)')
    src.add_argument('--fetch',  '-f', action='store_true',
                     help=f'Fetch latest graph from {GRAPH_API_URL}')
    p.add_argument('--save',        '-s', metavar='FILE', default=None,
                   help='Save fetched graph JSON to FILE')
    nsrc = p.add_mutually_exclusive_group()
    nsrc.add_argument('--nodes',       '-n', metavar='FILE', default='nodes.json',
                      help='Node location JSON file (default: nodes.json)')
    nsrc.add_argument('--fetch-nodes', '-N', action='store_true',
                      help=f'Fetch node locations from {NODES_API_URL}')
    p.add_argument('--save-nodes',  metavar='FILE', default=None,
                   help='Save fetched node data to FILE')
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

    if args.fetch_nodes:
        nodes_raw = fetch_nodes(save_path=args.save_nodes)
        loc_by_pubkey = load_node_locations(data=nodes_raw)
    elif os.path.exists(args.nodes):
        loc_by_pubkey = load_node_locations(path=args.nodes)
    else:
        print(f'No node location file at {args.nodes!r} — use --nodes or --fetch-nodes', file=sys.stderr)
        loc_by_pubkey = {}

    communities = compute_metrics(g)
    attach_locations(g, loc_by_pubkey)
    print_summary(g, communities, skipped)
    save_static(g, args.pdf)
    save_interactive(g, args.html)
