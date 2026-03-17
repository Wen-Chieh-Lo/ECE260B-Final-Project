# ECE260B-Final-Project .gitignore 分析報告

## 分析摘要

- **總追蹤檔案數**: 2,459
- **產物檔數量**: 約 677 個（.gds2, .def, .lef, .sdf, .lib, .gz 等）
- **問題**: 大量 PnR、模擬產物已被納入版本控制

---

## 目前被追蹤但不應納入 Git 的檔案類型

### 1. 模擬產物 (Xcelium/Simvision)
| 類型 | 範例 | 說明 |
|------|------|------|
| xcelium.d/ | workspace/Step1/post_sim/xcelium.d/ | 模擬快取，可重新產生 |
| waves.shm/ | waves.shm/waves.dsn | 波形資料庫 |
| .simvision/ | .simvision/dbrowser-bookmarks | Simvision 設定 |
| xrun.key | post_sim/xrun.key | Xcelium 授權檔 |
| xrun.log | post_sim/xrun.log | 執行日誌 |

### 2. PnR 產物 (Innovus)
| 類型 | 數量 | 說明 |
|------|------|------|
| *.gds2 | 18 | 版圖檔，體積大 |
| *.def | 16 | 定義檔 |
| *.lef | 31 | 佈局交換格式 |
| *_BC.sdf, *_WC.sdf | 33 | 時序延遲 |
| *_BC.lib, *_WC.lib | 77 | Liberty 檔 |
| *.enc.dat/ | 325+ | Innovus 資料庫 |
| *.gz (timingReports) | 多個 | 時序報告 |

### 3. Synopsys 日誌
| 類型 | 範例 |
|------|------|
| filenames_*.log | filenames_11527_D20260310.log |

### 4. PnR 報告檔
| 類型 | 說明 |
|------|------|
| *.checkPin.rpt | Pin 檢查報告 |
| *.conn.rpt | 連線報告 |
| *.geom.rpt | 幾何報告 |
| *.post_route.*.rpt | 繞線後報告 |
| power.rpt | 功耗報告 |

---

## 已更新 .gitignore

已新增規則以忽略上述產物。**注意**：已追蹤的檔案不會自動從 Git 移除。

### 若要從追蹤中移除（保留本地檔案）：

```bash
# 預覽會被移除追蹤的檔案
git ls-files | grep -E '\.(gds2|def|lef|sdf|gz)$|xcelium\.d|waves\.shm|\.simvision|xrun\.' | head -50

# 從 Git 追蹤移除（保留本地檔案）
git rm -r --cached workspace/*/pnr/**/*.enc.dat 2>/dev/null
git rm --cached **/xcelium.d **/waves.shm **/.simvision **/xrun.key 2>/dev/null
# ... 或使用 git filter 批次處理
```

### 建議：分批移除大型產物

```bash
# 1. 移除 Innovus 資料庫
git rm -r --cached 'workspace/*/pnr/**/*.enc.dat' 2>/dev/null

# 2. 移除模擬產物
find . -path '*/xcelium.d' -o -path '*/waves.shm' -o -path '*/.simvision' | xargs git rm -r --cached 2>/dev/null

# 3. 提交變更
git add .gitignore
git commit -m "Update .gitignore and remove generated files from tracking"
```

---

## 預期效果

移除產物檔追蹤後可望：
- 減少 .git 體積
- 加快 clone/pull
- 避免磁碟配額問題
