const axios = require("axios");
const https = require("https");

class SplunkLogger {
    constructor(splunkToken, splunkUrl) {
        if (!splunkToken || !splunkUrl) {
            console.warn("SplunkLogger: Missing token or URL. Logging will be disabled.");
        }
        this.splunkToken = splunkToken;
        this.splunkUrl = splunkUrl;
        this.httpsAgent = new https.Agent({ rejectUnauthorized: false });
    }

    async send(logMessage, level = "info") {
        if (!this.splunkToken || !this.splunkUrl) {
            console.error("SplunkLogger is not properly initialized. Skipping log.");
            return;
        }

        const payload = {
            event: {
                level: level,
                message: logMessage,
            }
        };

        try {
            const response = await axios.post(`${this.splunkUrl}/services/collector`, payload, {
                headers: {
                    "Authorization": `Splunk ${this.splunkToken}`,
                    "Content-Type": "application/json",
                },
                httpsAgent: this.httpsAgent
            });

            console.log(`Splunk Log Sent: ${response.status}`);
        } catch (error) {
            console.error("Failed to send log to Splunk:", error);
        }
    }
}

module.exports = SplunkLogger;
