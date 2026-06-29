# CHNG-001: Design — Analytics UI

## Overview
Analytics dashboard with charts, metrics, and data visualization for consultant performance.

## Components
- Revenue charts (daily, monthly, annual)
- COEF percentage trends
- Consultant roster table with search/sort
- Client financial breakdown

## Data Flow
Frontend fetches report data from `/api/report/*` endpoints and renders charts via SVG.
No backend changes — all analytics are computed server-side by ReportService.
