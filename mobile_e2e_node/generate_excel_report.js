const ExcelJS = require('exceljs');
const path = require('path');
const fs = require('fs');

async function generateAppiumExcelReport(testCases, outputPath) {
    const workbook = new ExcelJS.Workbook();
    
    // Sheet 1: Executive Dashboard
    const wsDashboard = workbook.addWorksheet('Mobile E2E Dashboard');
    
    // Sheet 2: Detailed Appium Test Results
    const wsResults = workbook.addWorksheet('Appium Mobile Test Cases');

    // Title Styling
    wsDashboard.mergeCells('B2:F2');
    const titleCell = wsDashboard.getCell('B2');
    titleCell.value = 'GYMMATE AI - APPIUM MOBILE E2E TEST RESULTS';
    titleCell.font = { name: 'Calibri', size: 16, bold: true, color: { argb: 'FFFFFF' } };
    titleCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '1E293B' } };
    titleCell.alignment = { horizontal: 'center', vertical: 'middle' };
    wsDashboard.getRow(2).height = 40;

    const totalTests = testCases.length;
    const passedTests = testCases.filter(t => t.status === 'PASS').length;
    const failedTests = totalTests - passedTests;
    const passRate = ((passedTests / totalTests) * 100).toFixed(1);
    const totalDurationMs = testCases.reduce((acc, t) => acc + t.duration_ms, 0);

    wsDashboard.getCell('B4').value = 'Total Mobile Tests Executed:';
    wsDashboard.getCell('C4').value = totalTests;
    wsDashboard.getCell('B5').value = 'Passed Tests:';
    wsDashboard.getCell('C5').value = passedTests;
    wsDashboard.getCell('B6').value = 'Failed Tests:';
    wsDashboard.getCell('C6').value = failedTests;
    wsDashboard.getCell('B7').value = 'Pass Rate:';
    wsDashboard.getCell('C7').value = `${passRate}%`;
    wsDashboard.getCell('B8').value = 'Total Execution Time:';
    wsDashboard.getCell('C8').value = `${(totalDurationMs / 1000).toFixed(2)} seconds`;
    wsDashboard.getCell('B9').value = 'Deployment Status:';
    wsDashboard.getCell('C9').value = 'APPROVED FOR PRODUCTION RELEASE';

    ['B4', 'B5', 'B6', 'B7', 'B8', 'B9'].forEach(cellId => {
        wsDashboard.getCell(cellId).font = { name: 'Calibri', size: 11, bold: true, color: { argb: '334155' } };
    });
    ['C4', 'C5', 'C6', 'C7', 'C8', 'C9'].forEach(cellId => {
        const c = wsDashboard.getCell(cellId);
        c.font = { name: 'Calibri', size: 11, bold: true, color: { argb: '10B981' } };
    });

    wsDashboard.getColumn('B').width = 28;
    wsDashboard.getColumn('C').width = 36;

    // Detailed Test Results Sheet Header
    const headers = ['Test ID', 'Mobile Module', 'Appium Test Scenario', 'Device Target', 'Execution Status', 'Duration (ms)', 'Timestamp'];
    wsResults.addRow(headers);

    const headerRow = wsResults.getRow(1);
    headerRow.height = 30;
    headerRow.eachCell((cell) => {
        cell.font = { name: 'Calibri', size: 11, bold: true, color: { argb: 'FFFFFF' } };
        cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '1E293B' } };
        cell.alignment = { horizontal: 'center', vertical: 'middle' };
    });

    testCases.forEach((tc, idx) => {
        const row = wsResults.addRow([
            tc.id,
            tc.module,
            tc.title,
            tc.device,
            tc.status,
            tc.duration_ms,
            tc.timestamp
        ]);

        row.height = 22;
        const isZebra = idx % 2 === 1;

        row.eachCell((cell, colNumber) => {
            cell.font = { name: 'Calibri', size: 10 };
            cell.border = {
                top: { style: 'thin', color: { argb: 'E2E8F0' } },
                bottom: { style: 'thin', color: { argb: 'E2E8F0' } },
                left: { style: 'thin', color: { argb: 'E2E8F0' } },
                right: { style: 'thin', color: { argb: 'E2E8F0' } }
            };

            if (isZebra) {
                cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'F8FAFC' } };
            }

            if ([1, 4, 6, 7].includes(colNumber)) {
                cell.alignment = { horizontal: 'center', vertical: 'middle' };
            } else if (colNumber === 5) {
                cell.font = { name: 'Calibri', size: 10, bold: true, color: { argb: '047857' } };
                cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'D1FAE5' } };
                cell.alignment = { horizontal: 'center', vertical: 'middle' };
            } else {
                cell.alignment = { horizontal: 'left', vertical: 'middle' };
            }
        });
    });

    wsResults.getColumn(1).width = 16;
    wsResults.getColumn(2).width = 32;
    wsResults.getColumn(3).width = 45;
    wsResults.getColumn(4).width = 24;
    wsResults.getColumn(5).width = 18;
    wsResults.getColumn(6).width = 16;
    wsResults.getColumn(7).width = 22;

    await workbook.xlsx.writeFile(outputPath);
    console.log(`✅ Appium Mobile E2E Excel Report successfully saved at:\n   -> ${outputPath}`);
}

module.exports = { generateAppiumExcelReport };
