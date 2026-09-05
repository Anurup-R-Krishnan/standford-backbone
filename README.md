# Stanford Backbone & Internet2 Emulation (Python 3 Modernization)

Modernized fork of the Stanford Backbone network emulation and Automatic Test Packet Generation (ATPG) research codebase (originally developed 2012–2014 by Hongyi Zeng, Peyman Kazemian, et al. at Stanford University).

This repository has been fully modernized to run natively on **Python 3.14+**, modern **Mininet (2.3+)**, and **Open vSwitch (OVS)** on current Linux platforms while strictly preserving original research semantics and reproducibility.

---

## Modernization Overview & Changelog

### 1. Python 3.14 Environment & Architecture
- **Language Upgrade**: Fully upgraded from Python 2.7 to Python 3.14.7.
- **Multiprocessing Start Method (PEP 758)**: In Python 3.14 on Linux, the default process start method changed from `"fork"` to `"forkserver"`. Worker pools in `atpg_stanford.py` and `atpg_internet2.py` now explicitly configure `multiprocessing.set_start_method("fork", force=True)` so child processes inherit pre-loaded global transfer function state (`ntf_global`, `ttf_global`) without re-import uninitialization errors.
- **Bytecode Integrity**: Verified with `python -m compileall -q` across 100% of files in the repository (0 syntax or import errors).

### 2. Automated Codemods & Linting
- **`modernize`**: Applied syntax transformation across `configuration/`, `topology/`, and `utils/` (`print` statements, exception raising syntax, unicode strings, dictionary `.items()` iterators).
- **`ruff`**: Applied automated linter passes, import cleanup, f-string modernization, and removed obsolete Python 2 idioms.
- **Critical Pyflakes Bug Fixes**:
  - Eliminated undefined variables (`xrange` replaced with `range`, `unicode` with `str`, `RuntimeException` with `RuntimeError`).
  - Fixed duplicate method definition in `cisco_router_parser.py` where a fallback `get_transport_port_number` method accidentally masked the protocol port dictionary.
  - Resolved namespace imports in `pyopenflow-load-controller.py` and `cppize.py`.
  - Converted bare `except:` clauses to explicit `except Exception:`.

### 3. Core Research Pipeline & Semantic Fixes
- **Integer Division Math (`//` vs `/`)**:
  - In Python 3, `/` always produces floats. Converted port-to-switch ID math (`port // SWITCH_ID_MULTIPLIER`) in `emulated_tf.py`, `mininet_builder.py`, `mininet_rebuilder.py`, `gui.py`, and `gui-web.py` to prevent float switch IDs (e.g. `s5.00001` instead of `s5`) and float slice indexing exceptions (`TypeError: list indices must be integers or slices, not float`).
  - Fixed chunk division in ATPG (`len(rules) // chunk_size + 1`) to ensure integer slice step sizes in `chunks()`.
- **`random.sample` Compatibility**:
  - In Python 3.9+ deprecation and Python 3.11+ rejection of sets in `random.sample(set, k)`, updated sampling in ATPG to operate over deterministic sorted lists (`random.sample(sorted(src_port_ids_global), new_length)`).
  - Ensured sample size `k` is strictly an integer (`int(len(...) * percentage // 100)`).
- **Time Functions**:
  - Replaced deprecated/removed `time.clock` with `time.perf_counter` across all transfer function timing utilities in `configuration/utils/`.
- **Sorting Keywords**:
  - Removed obsolete Python 2 `cmp` parameter from `list.sort(cmp=None, key=None, reverse=True)` in `emulated_tf.py`.
- **SQLite Database Connection**:
  - Updated `sqlite3.connect(DATABASE_FILE, 6000)` to keyword argument `timeout=6000` to eliminate Python 3.15 deprecation warnings.
- **Dynamic Execution Paths**:
  - Modernized `scripts/stanford.sh` and `scripts/internet2.sh` to dynamically resolve directory paths via `BASH_SOURCE` and support custom python interpreter paths via `${PYTHON:-python3}`.
  - Fixed copy-paste output file redirect typo in `scripts/stanford.sh` (`stanford-40.txt`).
  - Added `-e` edge flag for edge test packet generation in `scripts/internet2.sh`.

---

## Quickstart

### Prerequisites
- Linux (Ubuntu 22.04/24.04, Arch Linux, Debian, etc.)
- Python 3.10+ (tested on Python 3.14.7)
- Open vSwitch and Mininet (`mininet` system package or source build)
- SQLite 3

### Environment Setup

```bash
# Clone the repository
git clone https://github.com/Anurup-R-Krishnan/standford-backbone.git
cd standford-backbone

# Create a virtual environment that has access to system Mininet packages
python3 -m venv --system-site-packages .venv
source .venv/bin/activate

# Install Python dependencies
pip install -r requirements.txt
```

---

## Running the Pipelines

### 1. Generate Transfer Functions & OpenFlow Rules

Generate IP forwarding and complete transfer functions from router configs:

```bash
cd configuration/utils

# Stanford Backbone (16 routers)
python generate_stanford_ip_fwd_tf.py
python generate_stanford_backbone_tf.py
python generate_stanford_openflow_rules.py

# Internet2 (9 routers)
python generate_internet2_backbone_tf.py
```

Generated rules and transfer functions are stored under `configuration/work/`.

### 2. Automatic Test Packet Generation (ATPG)

Run ATPG reachability analysis, test packet synthesis, and min-set-cover compression:

```bash
cd configuration/atpg

# Stanford Backbone (sample 10% of terminal pairs)
python atpg_stanford.py -p 10 -f stanford-10.sqlite

# Full batch test script
bash ../../scripts/stanford.sh

# Internet2
python atpg_internet2.py -p 10 -f i2-10.sqlite
bash ../../scripts/internet2.sh
```

### 3. Mininet Emulation & Topology Construction

Launch the Stanford backbone network topology in Mininet:

```bash
# View CLI options
sudo python topology/mininet_rebuilder.py --help

# Start Mininet with traffic generation
sudo python topology/mininet_rebuilder.py -t
```

---

## Original Getting Started & Experiments

The notes below document the original experiments and workflow from the 2012–2014 study:

### Getting Started
* The idea is to route ICMP traffic in the emulated Stanford-backbone network.
* Follow the [configuration instructions](configuration/Notes.md) to generate the necessary OpenFlow rules (translated from the Stanford-backbone network). 
* Follow the [controller instructions](controller/Notes.md) to setup the controller which installs the generated OpenFlow rules into Mininet. 
* Follow the [topology instructions](topology/Notes.md) to setup the Stanford-backbone topology in Mininet. Start controller before Mininet to prevent existing dummy flow entries from being cleared.
* From [mininet net output](topology/net.txt) (`mininet> net`), note the connection: `h197(h197-eth0) --- (s13-eth9)s13(s13-eth8) --- (h196-eth0)h196`. So `h197` is where we initiate ICMP traffic.
* Check what routes are available at `s13` by `sudo ovs-ofctl dump-flows s13`. Look for: `priority=59929,ip,nw_dst=128.12.1.248/29 actions=output:5,output:8,output:2`. We can ping `128.12.1.249`. The ICMP traffic should be forwarded to both `s13-eth2` and `s13-eth8` but not to other ports.
* Prepare `h197` to initiate ICMP traffic:
  * View routing table: `h197 route -n`. Verify the default route is present.
  * Setup static ARP: `h197 arp -s 128.12.1.249 01:00:00:00:00:23`. Without this, the ping client cannot resolve MAC address.
* Start ICMP traffic: `h197 ping 128.12.1.249`.
* Verify forwarding:
  * Verify ingress at `s13`: `sudo tcpdump icmp -i s13-eth9 -nS`.
  * Verify forward at `s13`: `sudo tcpdump icmp -i s13-eth2 -nS` and `sudo tcpdump icmp -i s13-eth8 -nS`.
  * Check non-forwarded port: `sudo tcpdump icmp -i s13-eth3 -nS` (no ICMP traffic expected).

### Ping Google
* Prepare `h197` to initiate ICMP traffic to Google (`74.125.226.78`).
* Probe the path:
  * Use topology information to figure out peering ports.
  * Check matched flow entries: `sudo ovs-ofctl dump-flows s13 | grep -v n_packets=0`.
* The path of Google traffic:
  * `h197-eth0 > s13-eth9 > s13-eth1 > s1005-eth4 > s1005-eth1 > s2-eth13 > s2-eth4 > s1009-eth1 > s1009-eth2(s1009-eth3) > s3-eth1(s12-eth9) > s3-eth7(s12-eth1) > h67-eth0(s1007-eth3) > (s1007-eth1) > (s1-eth1) > (s1-eth4) > (h18-eth0)`
  * Traffic is forwarded to two destinations: border router `s1` (`bbra_rtr`) and operational zone router `s3` (`boza_rtr`).

### Ping Stanford & Fault Injection
* Prepare `h197` to initiate ICMP traffic to `stanford.cs.edu` (`171.64.64.64`).
* Probe path: `h197-eth0 > s13-eth9 > s13-eth6 > s1006-eth3 > s1006-eth1 > s1-eth32 > s1-eth22 > h33-eth0`.
* Inject fault:
  * Add dropping rule: `sudo ovs-ofctl add-flow s1 dl_type=0x0800,nw_dst=171.64.64.64/32,priority=65535,actions=`
  * Packets will be dropped at `s1`. Ingress traffic remains visible on `s1-eth32`, while egress on `s1-eth22` stops.
