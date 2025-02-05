'use strict';

const { handler } = require('../../app.js');
const { handleGetRequest } = require('../../handler/get_task');
const { handlePostRequest } = require('../../handler/create_task');
const chai = require('chai');
const expect = chai.expect;
const sinon = require('sinon');
const { Client } = require('pg');
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const SplunkLogger = require("../../utils/splunklog");

describe('Lambda Function Tests', function () {
    let clientStub, secretsManagerStub, queryStub, client, mockSplunkLogger;

    beforeEach(() => {
        clientStub = sinon.stub(Client.prototype, 'connect').resolves();
        client = new Client();

        secretsManagerStub = sinon.stub(SecretsManagerClient.prototype, 'send');
        secretsManagerStub.withArgs(sinon.match.instanceOf(GetSecretValueCommand)).resolves({
            SecretString: JSON.stringify({
                password: "fake-db-password",
                dsn: "https://fake-sentry-dsn-v1",
                token: "fake-splunk-token"
            })
        });

        mockSplunkLogger = new SplunkLogger("fake-splunk-token", "https://fake-splunk-url");
        sinon.stub(mockSplunkLogger, 'send').resolves();
    });

    afterEach(() => {
        sinon.restore();
    });

    const parseResponse = (result) => {
        expect(result).to.be.an('object');
        expect(result.body).to.be.a('string');
        return JSON.parse(result.body);
    };

    describe('Handler (index.js)', function () {
        this.timeout(5000); // Set 5 seconds timeout
    
        it('should return a successful response', async () => {
            const event = { requestContext: { http: { method: 'GET' } } };
            const context = { callbackWaitsForEmptyEventLoop: true };
    
            try {
                console.log("Before calling handler...");
                const result = await handler(event, context);
                console.log("Handler result:", result);
    
                const response = parseResponse(result);
    
                expect(result.statusCode).to.equal(200);
                expect(response).to.be.an('object');
                expect(response.message).to.equal('hello world');
    
                sinon.assert.called(mockSplunkLogger.send);
            } catch (error) {
                console.error('Test failed with error:', error);
                throw error;
            }
        });
    });
    

    describe('handleGetRequest', function () {
        it('should return tasks successfully', async () => {
            queryStub = sinon.stub(client, 'query').resolves({
                rows: [{ id: 1, title: 'Test Task', description: 'Test Description' }]
            });

            const result = await handleGetRequest(client, mockSplunkLogger);
            const response = parseResponse(result);

            expect(result.statusCode).to.equal(200);
            expect(response).to.be.an('array');
            expect(response[0].title).to.equal('Test Task');

            sinon.assert.called(mockSplunkLogger.send);
        });

        it('should handle database errors', async () => {
            queryStub = sinon.stub(client, 'query').throws(new Error('Database error'));

            const result = await handleGetRequest(client, mockSplunkLogger);
            const response = parseResponse(result);

            expect(result.statusCode).to.equal(500);
            expect(response.message).to.equal('Internal Server Error');

            sinon.assert.called(mockSplunkLogger.send);
        });
    });

    describe('handlePostRequest', function () {
        it('should create a task successfully', async () => {
            const event = { body: JSON.stringify({ title: 'New Task', description: 'New Description' }) };
            queryStub = sinon.stub(client, 'query').resolves({
                rows: [{ id: 1, title: 'New Task', description: 'New Description' }]
            });

            const result = await handlePostRequest(event, client, mockSplunkLogger);
            const response = parseResponse(result);

            expect(result.statusCode).to.equal(201);
            expect(response.title).to.equal('New Task');

            sinon.assert.called(mockSplunkLogger.send);
        });

        it('should return validation error when title is missing', async () => {
            const event = { body: JSON.stringify({ title: '' }) };

            const result = await handlePostRequest(event, client, mockSplunkLogger);
            const response = parseResponse(result);

            expect(result.statusCode).to.equal(400);
            expect(response.message).to.equal('Title and description are required');

            sinon.assert.called(mockSplunkLogger.send);
        });

        it('should handle database errors', async () => {
            const event = { body: JSON.stringify({ title: 'New Task', description: 'New Description' }) };
            queryStub = sinon.stub(client, 'query').throws(new Error('Database error'));

            const result = await handlePostRequest(event, client, mockSplunkLogger);
            const response = parseResponse(result);

            expect(result.statusCode).to.equal(500);
            expect(response.message).to.equal('Internal Server Error');

            sinon.assert.called(mockSplunkLogger.send);
        });
    });
});
