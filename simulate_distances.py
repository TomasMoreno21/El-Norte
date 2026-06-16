import math

DT = 0.001  # 1ms steps
SPEED_CAP_DIFF = 500 + 800 * 0.6  # 833.33... actually: 500 + diff * 0.6 = 1000 => diff = 500/0.6 = 833.333...
PHASE1_CAP_DIFF = 833.3333333333334
PHASE1_CAP_TIME = 100 * math.log(2)  # ≈ 69.3147...

PIXEL_TO_METER = 60  # not needed directly, formulas already factor it

# Helper: time to reach distance in current system (analytical)
def current_time_to_distance(target_distance, speed_bonus, bird_speed_mult):
    mult = speed_bonus * bird_speed_mult
    diff_needed = target_distance / mult
    if diff_needed <= PHASE1_CAP_DIFF:
        return 100 * math.log(1 + diff_needed / 833.3333333333334)
    else:
        t_phase1 = PHASE1_CAP_TIME
        extra_diff = diff_needed - PHASE1_CAP_DIFF
        # d(diff)/dt = 1000/60 = 50/3
        t_extra = extra_diff / (1000 / 60)
        return t_phase1 + t_extra

# Helper: time to reach distance in new system (numerical)
def new_time_to_distance(target_distance, speed_bonus, bird_speed_mult):
    mult = speed_bonus * bird_speed_mult
    diff_needed = target_distance / mult
    diff = 0.0
    t = 0.0
    # If already at or past target
    if diff_needed <= 0:
        return 0.0
    while diff < diff_needed:
        v = 500 + 725 * (1 - math.exp(-diff / 3500))
        diff += v / 60 * DT
        t += DT
    return t

def format_time(seconds):
    if seconds < 120:
        return f"{round(seconds)}s"
    m = int(seconds // 60)
    s = round(seconds % 60)
    if s == 0:
        return f"{m}m"
    return f"{m}m {s}s"

# Define scenarios
scenarios = [
    ("Hornero", 1.0, 1.0, "current"),
    ("Tero", 1.4, 1.0, "current"),
    ("Carpintero", 0.9, 1.0, "current"),
    ("Hornero max upgrade", 1.0, 1.25, "current"),
    ("Tero max upgrade", 1.4, 1.25, "current"),
    ("Hornero new", 1.0, 1.0, "new"),
    ("Tero new", 1.4, 1.0, "new"),
    ("Carpintero new", 0.9, 1.0, "new"),
]

distances = [500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000, 6000, 7000, 8000, 9000, 10000]

# Build table
header = "| Distancia | " + " | ".join(s[0] for s in scenarios) + " |"
sep = "|" + "|".join("---" for _ in range(len(scenarios) + 1)) + "|"

rows = []
for d in distances:
    cells = [f"{d}m"]
    for bird_mult, sb, mode in [(s[1], s[2], s[3]) for s in scenarios]:
        if mode == "current":
            t = current_time_to_distance(d, sb, bird_mult)
        else:
            t = new_time_to_distance(d, sb, bird_mult)
        cells.append(format_time(t))
    rows.append("| " + " | ".join(cells) + " |")

print(header)
print(sep)
for r in rows:
    print(r)

# Also print raw seconds for verification
print("\n\n## Raw seconds\n")
print("| Distancia | " + " | ".join(s[0] for s in scenarios) + " |")
print(sep)
for d in distances:
    cells = [f"{d}m"]
    for bird_mult, sb, mode in [(s[1], s[2], s[3]) for s in scenarios]:
        if mode == "current":
            t = current_time_to_distance(d, sb, bird_mult)
        else:
            t = new_time_to_distance(d, sb, bird_mult)
        cells.append(f"{t:.2f}")
    print("| " + " | ".join(cells) + " |")
