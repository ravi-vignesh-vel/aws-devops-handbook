**HTTP Status Codes Reference Guide**  
**Quick Troubleshooting & Memory Aid**  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANklEQVR4nO3OQQmAABRAsSfYxZo/khWsYQLPJrCCNxG2BFtmZquOAAD4i3Ot7mr/egIAwGvXA4qjBdKlX6OKAAAAAElFTkSuQmCC)  
**1xx - Informational (Request In Progress)**  
*"Hey, I got your message, processing it..."*  
| | | | | | |  
|-|-|-|-|-|-|  
| **Code** | **Name** | **Layman's Term** | **Technical Meaning** | **Common Causes** | **Where to Troubleshoot** |   
| **100** | Continue | Interim response | Server received request headers, waiting for body | Client waiting for confirmation | Client-side code, server delays |   
| **101** | Switching Protocols | Protocol upgrade | Server switching to WebSocket/HTTP/2 | WebSocket upgrade requests | Check WebSocket config, proxy support |   
   
**Remember**: 1xx = Usually hidden from users, internal handshake.  **Rarely seen in logs.**  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANUlEQVR4nO3OMQ2AABAAsSNBCUrfDqrYGVDAgAU2QtIq6DIzW7UHAMBfHGt1V+fXEwAAXrseHCQGBEuErVgAAAAASUVORK5CYII=)  
**2xx - Success (Request Completed ✅)**  
*"Perfect! Got it, processed it, all good!"*  
| | | | | | |  
|-|-|-|-|-|-|  
| **Code** | **Name** | **Layman's Term** | **Technical Meaning** | **Common Causes** | **Where to Troubleshoot** |   
| **200** | OK | Success | Request successful, response contains data | Normal successful request | If missing: check app logic, DB errors |   
| **201** | Created | Resource made | New resource created (POST successful) | POST to create resource | Check resource creation logic |   
| **202** | Accepted | Task queued | Request accepted but not completed yet | Async jobs, background tasks | Check job queue, task scheduler |   
| **204** | No Content | Success, no data | Request succeeded but no response body (DELETE OK) | DELETE requests, logout endpoints | Normal behavior—no action needed |   
| **206** | Partial Content | Resume download | Client requested partial file (Range header) | Resume downloads, video streaming | Check Range header support in server |   
   
**Remember**: 2xx = Happy path.  **If not seeing 200, something broke.**  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANUlEQVR4nO3OMQ2AABAAsSNhwgJmkPYLLpnRgQU2QtIq6DIze3UGAMBf3Gu1VcfHEQAA3rseaHkEMn1wK7sAAAAASUVORK5CYII=)  
**3xx - Redirection (Go Somewhere Else)**  
*"Wrong address, try over there instead..."*  
| | | | | | |  
|-|-|-|-|-|-|  
| **Code** | **Name** | **Layman's Term** | **Technical Meaning** | **Common Causes** | **Where to Troubleshoot** |   
| **300** | Multiple Choices | Pick one | Multiple URLs available for resource | Rare, old API design | API documentation |   
| **301** | Moved Permanently | Permanent redirect | Resource moved, update bookmarks | Domain migration, URL restructuring | Check redirect rules, old URLs in code |   
| **302** | Found (Temp Redirect) | Temporary move | Resource temporarily at new URL | Maintenance, A/B testing, temporary domains | Check app redirect logic, load balancer config |   
| **304** | Not Modified | Cache is fresh | Browser cache is still valid, no update | Browser caching working correctly | Browser DevTools (Network tab), cache headers |   
| **307** | Temp Redirect | Preserve method | Like 302 but keeps POST as POST (not GET) | Temporary redirects with form data | Check redirect handling, check 302 vs 307 |   
| **308** | Permanent Redirect | Permanent, keep method | Like 301 but keeps method (POST stays POST) | API versioning, permanent URL changes | Check API version endpoints |   
   
**Remember**: 3xx = Detour.  **Browser follows automatically** (but can cause infinite loops if misconfigured).  
**Quick troubleshooting**:  
- **Redirect loop?** → Check redirect rules (A→B→A)  
- **Wrong redirect code?** → 301/308 = permanent, 302/307 = temporary  
- **Losing POST data?** → Use 307/308, not 302/301  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAALUlEQVR4nO3OQQ0AIAwEsAMlSJ0UrOFkGngRklZBR1WtJDsAAPzizNcDAADuNcKwAyU+nb+5AAAAAElFTkSuQmCC)  
**4xx - Client Error (Your Request Was Wrong)**  
*"YOU messed up. Here's what went wrong..."*  
| | | | | | |  
|-|-|-|-|-|-|  
| **Code** | **Name** | **Layman's Term** | **Technical Meaning** | **Common Causes** | **Where to Troubleshoot** |   
| **400** | Bad Request | Malformed request | Server can't understand the request format | Missing headers, invalid JSON, wrong format | Check request body format (JSON), headers, query params |   
| **401** | Unauthorized | Need to login | Authentication missing or invalid | Missing token, expired token, wrong credentials | Check auth headers, JWT expiry, login endpoint |   
| **403** | Forbidden | No permission | Authenticated but not allowed to access | Wrong role, insufficient permissions, IP blocked | Check user permissions, RBAC rules, firewall rules |   
| **404** | Not Found | Wrong address | Resource doesn't exist | Typo in URL, deleted resource, wrong endpoint | Check URL spelling, API documentation, verify resource exists |   
| **405** | Method Not Allowed | Wrong action | HTTP method not supported (POST to GET-only endpoint) | Using POST on GET-only endpoint, wrong verb | Check API docs, use correct HTTP verb (GET/POST/PUT/DELETE) |   
| **408** | Request Timeout | Took too long | Client took too long to send complete request | Slow network, network disconnection | Check client network, timeout settings |   
| **409** | Conflict | Data collision | Can't process due to conflicting data (duplicate, version mismatch) | Duplicate entry, concurrent updates, version conflict | Check for duplicates, retry with new data, check version |   
| **410** | Gone | Deleted forever | Resource permanently deleted, won't come back | API deprecated, resource removed | Check API changelog, use alternative endpoint |   
| **413** | Payload Too Large | File too big | Request body exceeds max size | Uploading huge file, POST data too large | Check file size limits, compression, chunked uploads |   
| **414** | URI Too Long | URL too long | URL exceeds max length | Too many query params, oversized headers | Reduce query params, use POST instead of GET with params |   
| **415** | Unsupported Media Type | Wrong format | Server doesn't accept this data format (wrong Content-Type) | Sending XML when API expects JSON, wrong MIME type | Check Content-Type header, use application/json |   
| **429** | Too Many Requests | Slow down! | Rate limit exceeded, too many requests | Hammering API, no backoff strategy, bot-like behavior | Implement exponential backoff, check rate limit headers |   
   
**Remember**: 4xx =  **CLIENT'S fault**. Errors are in YOUR request.  
**Quick troubleshooting checklist**:  
- **401?** → Add auth token (Authorization: Bearer token)  
- **403?** → Check permissions, role, API key scope  
- **404?** → Verify URL/endpoint exists  
- **400?** → Validate JSON, check required fields  
- **429?** → Add delay between requests, check rate limit headers  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANElEQVR4nO3OUQmAABBAsSeILQSjXgcrmkOs4J8IW4ItM7NXZwAA/MW1Vlt1fBwBAOC9+wEukwQ+V/SggAAAAABJRU5ErkJggg==)  
**5xx - Server Error (Server Broke)**  
*"We messed up. Our fault, try again later..."*  
| | | | | | |  
|-|-|-|-|-|-|  
| **Code** | **Name** | **Layman's Term** | **Technical Meaning** | **Common Causes** | **Where to Troubleshoot** |   
| **500** | Internal Server Error | App crashed | Generic server error, something broke | App exception, unhandled error, null pointer | Check app logs, error stack trace, recent deployments |   
| **501** | Not Implemented | Feature missing | Server doesn't support this method | Method not coded yet, feature incomplete | Check API documentation, feature roadmap |   
| **502** | Bad Gateway | Upstream died | Gateway can't reach backend server | Backend service down, connection refused, timeout | Check backend service health, logs, networking (telnet, curl) |   
| **503** | Service Unavailable | Temporarily down | Server overloaded or in maintenance | High load, crash, restart, DB connection pool exhausted | Check resource usage (CPU, RAM, connections), deployment status |   
| **504** | Gateway Timeout | Upstream too slow | Gateway waiting for backend too long | Slow backend query, blocking operation, infinite loop | Check backend response time, database query performance, code bottlenecks |   
| **505** | HTTP Version Not Supported | Outdated protocol | Server doesn't support HTTP version used | Misconfigured client sending HTTP/0.9 | Check server HTTP version support, upgrade client |   
| **506** | Variant Also Negotiates | Content negotiation error | Server misconfiguration | Bad content negotiation config | Check Vary header, Accept headers, server configuration |   
| **507** | Insufficient Storage | Disk full | Server ran out of disk space | /var/log full, database disk full, storage exhausted | Check disk usage: df -h, cleanup logs, add storage |   
| **508** | Loop Detected | Infinite redirect | Server detected infinite loop in request | Misconfigured redirects, DAV loops | Check redirect rules, remove circular redirects |   
| **510** | Not Extended | Missing extension | Server requires extension to process request | WebDAV extension missing, deprecated feature | Check server extensions, update configuration |   
   
**Remember**: 5xx =  **SERVER'S fault**. Problem is on the backend.  
**Quick troubleshooting priority**:  
- **502/504?** → ping backend, curl backend-ip:port, check services running  
- **503?** → Check CPU/RAM, restart service, check DB connections  
- **500?** → Tail app logs: tail -f /var/log/app.log, look for exception stack trace  
- **507?** → Run df -h, cleanup, increase storage  
- **504?** → Check slow queries: slow_query_log, trace request times  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANElEQVR4nO3OQQmAUBBAwSf8GGLWDWFDY3ixgjcRZhLMNjNHdQYAwF9cq1rV/vUEAIDX7gcRXAQ2s/16gwAAAABJRU5ErkJggg==)  
**Quick Reference Cheat Sheet**  
2xx ✅ = Success, all good  
 3xx → = Redirect, follow the arrow  
 4xx ⚠️ = Client error, check YOUR request  
 5xx 💥 = Server error, backend is broken  
   
**Most Common in Production**  
| | |  
|-|-|  
| **Code** | **What to Do** |   
| **200** | Great! Nothing to do |   
| **301/302** | Check redirect rules |   
| **400** | Fix request format (JSON, headers) |   
| **401** | Add/refresh auth token |   
| **403** | Check permissions/API key scope |   
| **404** | Verify URL/endpoint exists |   
| **429** | Add delay, implement backoff |   
| **500** | Check app logs, find exception |   
| **502** | Ping backend service, check if running |   
| **503** | Check disk/memory, restart service |   
| **504** | Trace slow backend queries/operations |   
   
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANklEQVR4nO3OQQmAABRAsSeYxZw/lieLGMACBrCCNxG2BFtmZquOAAD4i3Ot7mr/egIAwGvXA6fGBdgoVMwYAAAAAElFTkSuQmCC)  
**Troubleshooting Decision Tree**  
GET Status Code  
     │  
     ├─ 2xx? → Success, move on ✅  
     │  
     ├─ 3xx? → Follow redirect, check for loops  
     │  
     ├─ 4xx? → YOUR fault  
     │   ├─ 401? → Add auth token  
     │   ├─ 403? → Check permissions  
     │   ├─ 404? → Verify endpoint exists  
     │   ├─ 400? → Validate request body/headers  
     │   └─ 429? → Add backoff/delay  
     │  
     └─ 5xx? → THEIR fault  
         ├─ 500? → Check app logs  
         ├─ 502? → Check backend service (running?)  
         ├─ 503? → Check resources (disk, memory, connections)  
         ├─ 504? → Check slow queries/operations  
         └─ 507? → Check disk space (df -h)  
   
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANElEQVR4nO3OUQmAABBAsSeILQSjXgcrmkOs4J8IW4ItM7NXZwAA/MW1Vlt1fBwBAOC9+wEukwQ+V/SggAAAAABJRU5ErkJggg==)  
**DevOps Troubleshooting Commands**  
# Check if backend is reachable (502/504)  
 curl -v http://backend-service:port  
 telnet backend-ip port  
   
 # Check service status  
 systemctl status service-name  
 ps aux | grep service-name  
   
 # Check resource usage (503)  
 df -h          # Disk space  
 free -h        # Memory  
 top            # CPU, processes  
   
 # Check logs (500/502/504)  
 tail -f /var/log/application.log  
 journalctl -u service-name -f  
 docker logs container-name  
   
 # Check database connections  
 netstat -an | grep ESTABLISHED | wc -l  
 ss -s  # Socket statistics  
   
 # Check response times (504)  
 curl -w "@curl-format.txt" http://endpoint  
 ab -n 100 -c 10 http://endpoint  # Load test  
   
 # Monitor in real-time (Kubernetes)  
 kubectl logs -f deployment/name  
 kubectl describe pod pod-name  
 kubectl top nodes/pods  
   
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANUlEQVR4nO3OMQ2AABAAsSNBCUrfD6LYGNDAgAU2QtIq6DIzW7UHAMBfHGt1V+fXEwAAXrseHDAF/orRG+cAAAAASUVORK5CYII=)  
**Memory Aid: Status Code Pattern**  
- **1xx**: Info (rarely visible)  
- **2xx**: Success (1-2 numbers: 200, 201, 204, 206)  
- **3xx**: Move (red flags: loops, wrong method)  
- **4xx**: Client's fault (most common: 401, 403, 404, 429)  
- **5xx**: Server's fault (start with: logs, backend health, resources)  
**Pro tip**:  
- 4xx = "Did YOU mess up?" → Check request  
- 5xx = "Did WE mess up?" → Check server logs & infrastructure  
![](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAnEAAAACCAYAAAA3pIp+AAAABmJLR0QA/wD/AP+gvaeTAAAACXBIWXMAAA7EAAAOxAGVKw4bAAAANElEQVR4nO3OQQmAABRAsaeILbwZ9Fewo0Gs4E2ELcGWmTmqKwAA/uLeqr06v54AAPDa+gAthwNEfGhnhAAAAABJRU5ErkJggg==)  
