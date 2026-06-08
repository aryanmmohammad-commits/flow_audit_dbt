"""Synthetic B2B RevOps dataset for the Flow Audit dbt project.
Intentional obstructions (so the diagnostics find something real):
  - Big leak at the SQL -> Opportunity handoff (marketing/sales gap)
  - 'Negotiation' is the velocity bottleneck (deals stall there)
  - 'Paid Search' / 'Trade Show' = high volume, low conversion (vanity channels)
  - 'Referral' = low volume, high win-rate (the hidden gem)
  - 'AE Team B' is slower and wins less (a coaching signal)
  - A few whale deals create revenue concentration risk
"""
import csv, random, datetime as dt

random.seed(42)
REF = dt.date(2026, 6, 1)
iso = lambda x: x.isoformat()
def days_ago(n): return REF - dt.timedelta(days=n)

# ---- reps & teams -------------------------------------------------
teams = {"AE Team A": {"win": 1.0, "speed": 1.0},
         "AE Team B": {"win": 0.65, "speed": 1.7}}
names = ["Sanne","Daan","Lotte","Bram","Femke","Thijs","Noa","Lucas","Iris","Sem","Eva","Jens"]
reps = [{"rep_id": f"R{i:03d}", "rep_name": n,
         "team": "AE Team A" if i % 2 else "AE Team B",
         "hire_date": iso(days_ago(random.randint(200, 1400)))}
        for i, n in enumerate(names, 1)]

# ---- companies ----------------------------------------------------
industries = ["SaaS","Fintech","Logistics","Healthtech","Retail","Manufacturing","Media","Edtech"]
countries  = ["Netherlands","Germany","UK","Belgium","France","Spain"]
prefix = ["Nova","Lumen","Vega","Atlas","Orbit","Delta","Pine","Echo","Forge","Kite"]
suffix = ["Labs","Group","BV","Systems","Works","Digital"]
companies = [{"company_id": f"C{i:04d}",
              "company_name": f"{random.choice(prefix)}{random.choice(suffix)}-{i}",
              "industry": random.choice(industries),
              "employee_count": random.choice([15,40,75,120,250,500,900,1500]),
              "country": random.choice(countries)} for i in range(1, 221)]

# ---- channels: weight, mql, sql, opp, win, deal-size --------------
channels = {
    "Referral":      {"w": 8,  "mql": .82, "sql": .72, "opp": .80, "win": .55, "size": 28000},
    "Webinar":       {"w": 15, "mql": .60, "sql": .55, "opp": .55, "win": .40, "size": 22000},
    "Organic":       {"w": 18, "mql": .52, "sql": .46, "opp": .50, "win": .35, "size": 20000},
    "Paid Search":   {"w": 32, "mql": .46, "sql": .30, "opp": .32, "win": .22, "size": 16000},
    "Cold Outbound": {"w": 20, "mql": .34, "sql": .30, "opp": .30, "win": .18, "size": 19000},
    "Trade Show":    {"w": 25, "mql": .56, "sql": .34, "opp": .30, "win": .25, "size": 41000},
}
cnames = list(channels); cweights = [channels[c]["w"] for c in cnames]

base_days = {"Opportunity": 7, "Proposal": 12, "Negotiation": 28}  # Negotiation = bottleneck
act_types = ["Call","Email","Meeting","Demo"]

leads, deals, history, activities = [], [], [], []
dn = hn = an = 0

for li in range(1, 1601):
    src = random.choices(cnames, weights=cweights, k=1)[0]; cfg = channels[src]
    comp = random.choice(companies)
    created = days_ago(random.randint(20, 540))
    lead = {"lead_id": f"L{li:04d}", "company_id": comp["company_id"], "lead_source": src,
            "campaign": f"{src.split()[0].lower()}-q{random.randint(1,4)}",
            "created_at": iso(created), "mql_at": "", "sql_at": ""}
    mql = random.random() < cfg["mql"]
    mql_date = created + dt.timedelta(days=random.randint(2, 20)) if mql else None
    if mql: lead["mql_at"] = iso(mql_date)
    sql = mql and random.random() < cfg["sql"]
    sql_date = mql_date + dt.timedelta(days=random.randint(3, 25)) if sql else None
    if sql: lead["sql_at"] = iso(sql_date)
    leads.append(lead)

    if not (sql and random.random() < cfg["opp"]):
        continue  # the SQL -> Opportunity leak

    dn += 1; rep = random.choice(reps); t = teams[rep["team"]]
    deal_id = f"D{dn:04d}"
    dcreated = sql_date + dt.timedelta(days=random.randint(2, 10))
    amount = int(random.gauss(cfg["size"], cfg["size"] * 0.35))
    if random.random() < 0.04: amount = int(amount * random.uniform(4, 8))  # whale
    amount = max(3000, amount)

    # build the FULL stage timeline, then clip everything after REF (today)
    timeline, cur = [], dcreated
    timeline.append(("Opportunity", cur))
    cur += dt.timedelta(days=int(base_days["Opportunity"] * t["speed"] * random.uniform(.6, 1.4)))
    if random.random() < 0.82:
        timeline.append(("Proposal", cur))
        cur += dt.timedelta(days=int(base_days["Proposal"] * t["speed"] * random.uniform(.6, 1.4)))
        if random.random() < 0.78:
            timeline.append(("Negotiation", cur))
            cur += dt.timedelta(days=int(base_days["Negotiation"] * t["speed"] * random.uniform(.6, 1.6)))
            # a deal that reached Negotiation eventually resolves
            won_roll = random.random() < (cfg["win"] * t["win"])
            timeline.append(("Closed Won" if won_roll else "Closed Lost", cur))

    # clip to what is observable as of REF
    visible = [(s, w) for (s, w) in timeline if w <= REF]
    if not visible:
        visible = [("Opportunity", dcreated)]
    current = visible[-1][0]
    is_closed = current in ("Closed Won", "Closed Lost")
    is_won = current == "Closed Won"
    closed_at = iso(visible[-1][1]) if is_closed else ""

    deals.append({"deal_id": deal_id, "company_id": comp["company_id"], "lead_id": lead["lead_id"],
                  "owner_id": rep["rep_id"], "amount": amount, "created_at": iso(dcreated),
                  "current_stage": current, "is_closed": 1 if is_closed else 0,
                  "is_won": 1 if is_won else 0, "closed_at": closed_at})
    for stage, when in visible:
        hn += 1
        history.append({"history_id": f"H{hn:05d}", "deal_id": deal_id, "stage": stage, "entered_at": iso(when)})
    # a few activities per deal, bounded by what's observable
    end = visible[-1][1]
    for _ in range(random.randint(2, 6)):
        an += 1
        span = max(1, (end - dcreated).days)
        activities.append({"activity_id": f"A{an:05d}", "deal_id": deal_id,
                           "activity_type": random.choice(act_types),
                           "activity_at": iso(dcreated + dt.timedelta(days=random.randint(0, span)))})

def dump(fn, rows, cols):
    with open(f"seeds/{fn}", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=cols); w.writeheader(); w.writerows(rows)

dump("raw_reps.csv", reps, ["rep_id","rep_name","team","hire_date"])
dump("raw_companies.csv", companies, ["company_id","company_name","industry","employee_count","country"])
dump("raw_leads.csv", leads, ["lead_id","company_id","lead_source","campaign","created_at","mql_at","sql_at"])
dump("raw_deals.csv", deals, ["deal_id","company_id","lead_id","owner_id","amount","created_at","current_stage","is_closed","is_won","closed_at"])
dump("raw_deal_stage_history.csv", history, ["history_id","deal_id","stage","entered_at"])
dump("raw_activities.csv", activities, ["activity_id","deal_id","activity_type","activity_at"])

print(f"reps={len(reps)} companies={len(companies)} leads={len(leads)} deals={len(deals)} history={len(history)} activities={len(activities)}")
won = sum(d["is_won"] for d in deals); closed = sum(d["is_closed"] for d in deals)
print(f"closed={closed} won={won} open={len(deals)-closed}")
