/// 로컬→서버 스왑 대비(상위 설계 §5/§8). Phase 1은 모두 pending으로 생성된다.
enum SyncStatus { pending, synced }
