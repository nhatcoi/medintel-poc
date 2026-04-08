                                                                                          
⏺ Toàn bộ luồng chạy ngon:                                                                                                                                                                         
                                                                                                                                                                                                   
  - Long-term memory: upsert_memory + get_all_memory hoạt động, bảng patient_memory đã tạo                                                                                                         
  - ReAct gather: chạy song 2 internal tool (recall_patient_memory + search_drug_kb), trả về 2 observation blocks                                                                                  
  - Short-term memory: sẵn sàng load qua load_recent_turns khi có session_id                                                                                                                       
  - LLM client: đã nhận history param                                                                                                                                                              
                                                                                                                                                                                                   
  Tóm tắt triển khai                                                                                                                                                                               
                                                                                                                                                                                                   
  ┌───────────────────────────────────┬──────────────────────────────────────────────────────────────────────┐                                                                                     
  │               File                │                              Trạng thái                              │                                                                                     
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────────────────┤                                                                                     
  │ app/models/patient_memory.py      │ mới — ORM PatientMemory (profile_id, key, value, source, confidence) │                                                                                     
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────────────────┤                                                                                     
  │ app/models/__init__.py            │ thêm import PatientMemory                                            │                                                                                     
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────────────────┤                                                                                     
  │ app/services/memory/short_term.py │ mới — load_recent_turns(session_id, limit)                           │                                                                                     
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────────────────┤                                                                                     
  │ app/services/memory/long_term.py  │ mới — CRUD + build_memory_context_block() + CANONICAL_KEYS           │                                                                                     
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────────────────┤                                                                                     
  │ app/services/agent/react_loop.py  │ mới — run_react_turn() orchestrator + gather_observations()          │                                                                                     
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────────────────┤                                                                                     
  │ ai/chatbot/llm_client.py          │ thêm param history: list[dict]                                       │                                                                                     
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────────────────┤                                                                                     
  │ ai/chatbot/prompts.py             │ bổ sung hướng dẫn về memory + history cho LLM                        │                                                                                     
  ├───────────────────────────────────┼──────────────────────────────────────────────────────────────────────┤                                                                                     
  │ app/services/chat_service.py      │ refactor — dùng run_react_turn thay vì gọi llm_reply trực tiếp       │                                                                                     
  └───────────────────────────────────┴──────────────────────────────────────────────────────────────────────┘                                                                                     
                                                                                                                                                                                                   
  Luồng mới của một lượt chat                                                                                                                                                                      
                                                                                                                                                                                                   
  User message                                                                                                                                                                                     
    │                                                                                                                                                                                              
    ▼                                                                                                                                                                                              
  chat_service.process_chat_message()                                                                                                                                                              
    │                                                                                                                                                                                              
    ├─ Resolve profile_id, session_id                                                                                                                                                              
    ├─ Build medication context (existing)                                                                                                                                                         
    │                                                                                                                                                                                              
    ▼                                                                                                                                                                                              
  react_loop.run_react_turn()                                                                                                                                                                      
    │                                                                                                                                                                                              
    ├─ gather_observations():                                                                                                                                                                      
    │    ├─ Tool: recall_patient_memory  ← long-term                                                                                                                                               
    │    └─ Tool: search_drug_kb          ← RAG (pgvector)                                                                                                                                         
    │                                                                                                                                                                                              
    ├─ load_recent_turns()               ← short-term (10 lượt)                                                                                                                                    
    │                                                                                                                                                                                              
    └─ llm_reply(user, history=[...], extra_context=merged)                                                                                                                                        
         │                                                                                                                                                                                         
         ▼                                                                                                                                                                                       
      JSON output: reply + tool_calls (write) + suggested_actions                                                                                                                                  
    │                                                                                                                                                                                              
    ▼
  Persist user+assistant message vào chat_messages                                                                                                                                                 
                                                                                                                                                                                                   
  Curl test
                                                                                                                                                                                                   
  # Turn 1 - tạo session mới                                
  curl -s -X POST http://127.0.0.1:8000/api/v1/chat/message \                                                                                                                                      
    -H 'Content-Type: application/json' \                                                                                                                                                          
    -d '{                                                                                                                                                                                          
      "text": "Metformin có uống trước hay sau ăn?",                                                                                                                                               
      "profile_id": "00000000-0000-0000-0000-000000000001",                                                                                                                                        
      "include_medication_context": true                                                                                                                                                           
    }' | jq                                                                                                                                                                                        
                                                                                                                                                                                                   
  # Turn 2 - dùng session_id từ turn 1 để test short-term memory                                                                                                                                   
  curl -s -X POST http://127.0.0.1:8000/api/v1/chat/message \
    -H 'Content-Type: application/json' \                                                                                                                                                          
    -d '{                                                   
      "text": "Thế còn liều tối đa thì sao?",                                                                                                                                                      
      "session_id": "<SESSION_ID_TU_TURN_1>",                                                                                                                                                      
      "profile_id": "00000000-0000-0000-0000-000000000001"                                                                                                                                         
    }' | jq                                                                                                                                                                                        
                                                                                                                                                                                                   
  Ở turn 2, LLM sẽ hiểu "nó" = Metformin nhờ short-term memory.                                                                                                                                    
                                                            
  Tiếp theo                                                                                                                                                                                        
                                                            
  Những thứ chưa làm (có thể bổ sung sau):                                                                                                                                                         
  1. Tool ghi long-term memory từ LLM — hiện chỉ server/code tự gọi upsert_memory. Nếu muốn LLM tự ghi, cần thêm tool update_patient_memory vào ALLOWED_TOOLS + handler trong chat_service để
  persist (cần kỹ để tránh LLM bịa fact).                                                                                                                                                          
  2. Iterative ReAct — hiện là "pre-planned ReAct" (1 lượt gather + 1 lượt LLM). Nếu cần LLM tự quyết search query (multi-query RAG), cần 2 LLM call: planner → executor.
  3. CAG (bước 4 trong plan) — cache response theo intent.                                                                                                                                         
  4. Agent 2 external fallback (bước 5).                                                                                                                                                           
                                                                                                                                                                                                   
  Muốn mình đi tiếp sang tool update_patient_memory cho LLM, hay chuyển sang CAG?  




⏺ Fallback đã trigger: RAG + Tavily external đều xuất hiện trong trace. ReAct loop hoàn chỉnh.

  Tóm tắt toàn bộ triển khai (bước 4 + 5)

  ┌──────────────────────────────────┬────────────┬─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │               File               │ Trạng thái │                                                    Nội dung                                                     │
  ├──────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ app/core/config.py               │ edit       │ cag_*, kb_version, tavily_*, rag_min_similarity                                                                 │
  ├──────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ .env.example                     │ edit       │ doc cho CAG_*, KB_VERSION, TAVILY_*                                                                             │
  ├──────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ app/models/response_cache.py     │ mới        │ ORM ResponseCache                                                                                               │
  ├──────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ app/models/__init__.py           │ edit       │ export ResponseCache                                                                                            │
  ├──────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ app/services/cag.py              │ mới        │ normalize_query, classify_intent, make_cache_key, get/set_cached, is_cacheable_*, invalidate_*, TTL theo intent │
  ├──────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ ai/agent2/__init__.py            │ mới        │ module init                                                                                                     │
  ├──────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ ai/agent2/tavily_client.py       │ mới        │ search() Tavily + build_external_context() với lọc trusted domains                                              │
  ├──────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ app/services/agent/react_loop.py │ edit       │ fallback Tavily khi _rag_is_confident()==False, MAX_STEPS=3                                                     │
  ├──────────────────────────────────┼────────────┼─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │ app/services/chat_service.py     │ edit       │ CAG lookup trước ReAct, CAG write sau nếu response an toàn                                                      │
  └──────────────────────────────────┴────────────┴─────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

  Luồng mới (tổng thể)

  User → process_chat_message
    │
    ├─ is_cacheable_request?  (không personal, không profile, không session)
    │     ├── YES → CAG lookup
    │     │       ├── HIT → return ngay (fast path, ~1ms)
    │     │       └── MISS → đi tiếp
    │     └── NO  → đi tiếp
    │
    ├─ run_react_turn (ReAct loop)
    │     ├── Observation 1: recall_patient_memory
    │     ├── Observation 2: search_drug_kb  ← Agent 1 (pgvector)
    │     ├── _rag_is_confident? NO →
    │     │     Observation 3: external_search (Tavily)  ← Agent 2
    │     ├── load_recent_turns (short-term memory)
    │     └── llm_reply(history + merged_context)
    │
    ├─ is_cacheable_response? (no write tools, no error)
    │     └── YES → CAG write (TTL theo intent)
    │
    └─ persist ChatMessage → return

  Cài đặt vào .env local

  Đã test với API key bạn cung cấp (hoạt động). Thêm vào server-med/.env:

  TAVILY_API_KEY=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
  TAVILY_ENABLED=true
  CAG_ENABLED=true
  KB_VERSION=1

  Lưu ý bảo mật: Bạn đã paste key ra chat. Key tvly-dev-* là dev key Tavily — nên rotate sau khi xong POC (Tavily dashboard → API Keys → Revoke).

  Curl test

  # Test CAG: chạy 2 lần, lần 2 phải nhanh (hit)
  curl -s -X POST http://127.0.0.1:8000/api/v1/chat/message \
    -H 'Content-Type: application/json' \
    -d '{"text":"Paracetamol dùng để làm gì?"}' | jq '.reply'

  time curl -s -X POST http://127.0.0.1:8000/api/v1/chat/message \
    -H 'Content-Type: application/json' \
    -d '{"text":"Paracetamol dùng để làm gì?"}' | jq '.reply'

  # Test Agent 2 fallback: hỏi thuốc không có trong KB nội bộ
  curl -s -X POST http://127.0.0.1:8000/api/v1/chat/message \
    -H 'Content-Type: application/json' \
    -d '{"text":"Trastuzumab side effects for elderly patients"}' | jq '.reply'

  Những gì CHƯA làm (để lần sau)

  1. Endpoint quản trị cache — POST /api/v1/admin/cag/invalidate, GET /api/v1/admin/cag/stats
  2. Auto-bump kb_version — sau mỗi lần ai.rag.ingest chạy xong, tự tăng kb_version (hiện phải sửa tay .env)
  3. Cache semantic — hiện cache theo exact-match normalized query; có thể mở rộng bằng embedding query để hit cả câu hỏi tương tự
  4. Iterative ReAct — hiện gather 1 vòng; có thể để LLM tự quyết gọi tool nào nếu câu phức tạp
  5. Rate-limit Tavily — cần nếu production (free tier 1000 req/tháng)

  Muốn mình làm tiếp endpoint admin cho CAG hay auto-bump kb_version?