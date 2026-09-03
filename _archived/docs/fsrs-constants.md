# FSRS-6 Constants and Formulas

## Core Constants

```python
STABILITY_DEFAULT = 2.5
DIFFICULTY_DEFAULT = 0.3
DECAY = -0.5
RETRIEVABILITY_THRESHOLD = 0.9
```

## DSR Model

| Variable | Range | Description |
|----------|-------|-------------|
| D (Difficulty) | 1-10 | How hard user finds topic |
| S (Stability) | days | Time for R to drop to 90% |
| R (Retrievability) | 0.0-1.0 | Recall probability |

## Core Formulas

### Retrievability

```
R(t) = (1 + t/(9*S))^D
```

Where:
- t = days since last review
- S = stability
- D = decay (-0.5)

### Next Interval

At 90% target retention: `interval = stability`

### Mastery

```
mastery = 1 - exp(decay * S / D)
```

## Default Weights

Optimized from 700M Anki reviews:

```python
DEFAULT_WEIGHTS = {
    'w1': 0.4, 'w2': 0.6, 'w3': 1.0, 'w4': 2.5,
    'w5': 3.0, 'w6': 0.5, 'w7': 1.0, 'w8': 0.2,
    'w9': 0.4, 'w10': 0.3, 'w11': 1.0, 'w12': 2.0,
    'w13': 0.1, 'w14': 0.2, 'w15': 0.3, 'w16': 0.4,
    'w17': 0.5
}
```

## Personalization Thresholds

| Reviews | Strategy |
|---------|----------|
| 0-100 | Use default weights |
| 100-1000 | Blend default + user weights |
| 1000+ | Fully personalized |
