# Routers package — one module per API area:
#   health   (M0)  liveness for Render
#   collect  (M1)  snippet ingestion, no-preflight simple requests
#   snippet  (M1)  serves /js/script.js
#   stats    (M1)  timeseries / breakdown / summary / live
#   auth     (M2)  admin password -> JWT
#   sites    (M2)  site CRUD + share-slug management
#   public   (M3)  read-only share-link mirror of stats
#   admin    (M1)  manual rollup fallback
