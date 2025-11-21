# Package Sorter

A package sorting service for Thoughtful's robotic automation factory. This service dispatches packages to the correct stack based on their volume and mass.

## Sorting Rules

### Classification Criteria

- **Bulky**: A package is bulky if:
  - Volume (Width x Height x Length) >= 1,000,000 cm^3, OR
  - Any single dimension >= 150 cm

- **Heavy**: A package is heavy if:
  - Mass >= 20 kg

### Stack Assignment

| Condition | Stack |
|-----------|-------|
| Neither bulky nor heavy | STANDARD |
| Bulky OR heavy (not both) | SPECIAL |
| Both bulky AND heavy | REJECTED |

## Installation

```bash
cd public/services/python/automation_factory # or your_git_clone_path
pip install -r requirements.txt
```

## Usage

### Direct Function Call

```python
from sorter import sort

# Returns: "STANDARD", "SPECIAL", or "REJECTED"
result = sort(width=10, height=10, length=10, mass=5)
print(result)  # STANDARD

# Bulky package (volume >= 1,000,000)
result = sort(width=100, height=100, length=100, mass=5)
print(result)  # SPECIAL

# Heavy package (mass >= 20)
result = sort(width=10, height=10, length=10, mass=25)
print(result)  # SPECIAL

# Both bulky and heavy
result = sort(width=100, height=100, length=100, mass=25)
print(result)  # REJECTED
```

### REST API

Start the server:

```bash
service_port=8000.  # You should change here to use different port.
uvicorn api:app --reload --host 0.0.0.0 --port ${SERVICE_PORT}
```

Or run directly:

```bash
python api.py
```

#### API Endpoints

**GET /**
- Returns API information

**POST /sort**
- Sort a package using JSON body

**GET /sort**
- Sort a package using query parameters

#### curl Examples

**POST request:**

```bash
# Standard package (small and light)
curl -X POST "http://localhost:${SERVICE_PORT}/sort" \
  -H "Content-Type: application/json" \
  -d '{"width": 10, "height": 10, "length": 10, "mass": 5}'
# Response: {"stack":"STANDARD","width":10.0,"height":10.0,"length":10.0,"mass":5.0}

# Bulky package (volume >= 1,000,000)
curl -X POST "http://localhost:${SERVICE_PORT}/sort" \
  -H "Content-Type: application/json" \
  -d '{"width": 100, "height": 100, "length": 100, "mass": 5}'
# Response: {"stack":"SPECIAL","width":100.0,"height":100.0,"length":100.0,"mass":5.0}

# Heavy package (mass >= 20)
curl -X POST "http://localhost:${SERVICE_PORT}/sort" \
  -H "Content-Type: application/json" \
  -d '{"width": 10, "height": 10, "length": 10, "mass": 25}'
# Response: {"stack":"SPECIAL","width":10.0,"height":10.0,"length":10.0,"mass":25.0}

# Rejected package (both bulky and heavy)
curl -X POST "http://localhost:${SERVICE_PORT}/sort" \
  -H "Content-Type: application/json" \
  -d '{"width": 100, "height": 100, "length": 100, "mass": 25}'
# Response: {"stack":"REJECTED","width":100.0,"height":100.0,"length":100.0,"mass":25.0}
```

**GET request:**

```bash
# Standard package
curl "http://localhost:${SERVICE_PORT}/sort?width=10&height=10&length=10&mass=5"

# Bulky package (single dimension >= 150)
curl "http://localhost:${SERVICE_PORT}/sort?width=150&height=10&length=10&mass=5"

# Rejected package
curl "http://localhost:${SERVICE_PORT}/sort?width=150&height=10&length=10&mass=25"
```

#### Interactive API Documentation

Once the server is running, visit:
- Swagger UI: http://localhost:${SERVICE_PORT}/docs
- ReDoc: http://localhost:${SERVICE_PORT}/redoc

## Running Tests

```bash
pytest test_sorter.py -v
```

## Project Structure

```
automation_factory/
├── sorter.py         # Core sorting logic
├── api.py            # FastAPI REST endpoints
├── test_sorter.py    # Unit tests
├── requirements.txt  # Python dependencies
└── README.md         # This file
```

## API Response Format

```json
{
  "stack": "STANDARD|SPECIAL|REJECTED",
  "width": 10.0,
  "height": 10.0,
  "length": 10.0,
  "mass": 5.0
}
```

## Error Handling

The API returns HTTP 400 for invalid inputs:

```bash
# Negative value
curl -X POST "http://localhost:${SERVICE_PORT}/sort" \
  -H "Content-Type: application/json" \
  -d '{"width": -10, "height": 10, "length": 10, "mass": 5}'
# Returns: 422 Unprocessable Entity with validation error details
```
