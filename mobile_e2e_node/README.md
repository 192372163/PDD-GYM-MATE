# 📱 GymMate AI - Node.js Appium E2E Mobile Automation Suite

This directory (`mobile_e2e_node`) contains the complete **Node.js Appium Mobile End-to-End Automation Test Suite** for GymMate AI.

## 📁 Directory Structure

```
c:\project pdd\gymmate_ai\mobile_e2e_node\
├── package.json               # Node.js dependencies & test scripts
├── index.js                   # Main execution entry point
├── appium_e2e_runner.js       # Appium 300+ Mobile E2E Test Suite
├── generate_excel_report.js   # Automated Excel Report Generator (ExcelJS)
├── appium_e2e_results.xlsx    # Generated Mobile E2E Excel Report
└── README.md                  # Instructions documentation
```

## 🚀 How to Run

### 1. Install Dependencies
```bash
npm install
```

### 2. Execute Mobile Appium E2E Test Suite & Generate Excel Report
```bash
npm test
```
*or*
```bash
node index.js
```

## 📊 Output Deliverable
Executing the test suite automatically generates a multi-tab, styled Excel report:
- `appium_e2e_results.xlsx` (saved in `mobile_e2e_node/` and synced to `testing/`)
