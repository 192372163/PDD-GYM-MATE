/**
 * Main Entry Point for GymMate AI Node.js Appium Mobile E2E Test Suite
 */

const { runMobileE2ETests } = require('./appium_e2e_runner');

(async () => {
    try {
        await runMobileE2ETests();
    } catch (error) {
        console.error("❌ Error executing Appium E2E Mobile Tests:", error);
        process.exit(1);
    }
})();
