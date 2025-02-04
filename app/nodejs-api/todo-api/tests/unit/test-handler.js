'use strict';

const { handler } = require('../../app.js');
const { handleGetRequest } = require('../../handler/get_task');
const { handlePostRequest } = require('../../handler/create_task');
const chai = require('chai');
const expect = chai.expect;
const sinon = require('sinon');
const { Client } = require('pg');
var event;

describe('Tests index', function () {
    let clientStub, sendLogsToSplunkStub;

    beforeEach(() => {
        clientStub = sinon.stub(Client.prototype, 'connect').resolves();
        sendLogsToSplunkStub = sinon.stub().resolves();
    });

    afterEach(() => {
        clientStub.restore();
        sinon.restore(); // Restore all stubs
    });

    it('verifies successful response', async () => {
        const event = { 
            headers: {}, 
            requestContext: { http: { method: 'GET' } } // Mock requestContext with HTTP method
        }; 
        const context = { callbackWaitsForEmptyEventLoop: true }; // Mock context
        const result = await handler(event, context);

        expect(result).to.be.an('object');
        expect(result.statusCode).to.equal(200);
        expect(result.body).to.be.an('string');

        let response = JSON.parse(result.body);

        expect(response).to.be.an('object');
        expect(response.message).to.be.equal("hello world");
        // expect(response.location).to.be.an("string");
    });
});

describe('Tests handleGetRequest', function () {
    let clientStub, sendLogsToSplunkStub;

    beforeEach(() => {
        clientStub = sinon.stub(Client.prototype, 'connect').resolves();
        sendLogsToSplunkStub = sinon.stub().resolves();
    });

    afterEach(() => {
        clientStub.restore();
        sinon.restore(); // Restore all stubs
    });

    it('verifies successful response', async () => {
        const client = new Client();
        const queryStub = sinon.stub(client, 'query').resolves({ rows: [{ id: 1, title: 'Test Task', description: 'Test Description' }] });

        const result = await handleGetRequest(client, sendLogsToSplunkStub);

        expect(result).to.be.an('object');
        expect(result.statusCode).to.equal(200);
        expect(result.body).to.be.an('string');

        let response = JSON.parse(result.body);

        expect(response).to.be.an('array');
        expect(response[0].title).to.equal('Test Task');
        queryStub.restore();
    });

    it('verifies error response', async () => {
        const client = new Client();
        const queryStub = sinon.stub(client, 'query').throws(new Error('Database error'));

        const result = await handleGetRequest(client, sendLogsToSplunkStub);

        expect(result).to.be.an('object');
        expect(result.statusCode).to.equal(500);
        expect(result.body).to.be.an('string');

        let response = JSON.parse(result.body);

        expect(response).to.be.an('object');
        expect(response.message).to.equal('Internal Server Error');
        queryStub.restore();
    });
});

describe('Tests handlePostRequest', function () {
    let clientStub, sendLogsToSplunkStub;

    beforeEach(() => {
        clientStub = sinon.stub(Client.prototype, 'connect').resolves();
        sendLogsToSplunkStub = sinon.stub().resolves();
    });

    afterEach(() => {
        clientStub.restore();
        sinon.restore(); // Restore all stubs
    });

    it('verifies successful response', async () => {
        const event = { body: JSON.stringify({ title: 'New Task', description: 'New Description' }) };
        const client = new Client();
        const queryStub = sinon.stub(client, 'query').resolves({ rows: [{ id: 1, title: 'New Task', description: 'New Description' }] });

        const result = await handlePostRequest(event, client, sendLogsToSplunkStub);

        expect(result).to.be.an('object');
        expect(result.statusCode).to.equal(201);
        expect(result.body).to.be.an('string');

        let response = JSON.parse(result.body);

        expect(response).to.be.an('object');
        expect(response.title).to.equal('New Task');
        queryStub.restore();
    });

    it('verifies validation error response', async () => {
        const event = { body: JSON.stringify({ title: '' }) };
        const client = new Client();

        const result = await handlePostRequest(event, client, sendLogsToSplunkStub);

        expect(result).to.be.an('object');
        expect(result.statusCode).to.equal(400);
        expect(result.body).to.be.an('string');

        let response = JSON.parse(result.body);

        expect(response).to.be.an('object');
        expect(response.message).to.equal('Title and description are required');
    });

    it('verifies error response', async () => {
        const event = { body: JSON.stringify({ title: 'New Task', description: 'New Description' }) };
        const client = new Client();
        const queryStub = sinon.stub(client, 'query').throws(new Error('Database error'));

        const result = await handlePostRequest(event, client, sendLogsToSplunkStub);

        expect(result).to.be.an('object');
        expect(result.statusCode).to.equal(500);
        expect(result.body).to.be.an('string');

        let response = JSON.parse(result.body);

        expect(response).to.be.an('object');
        expect(response.message).to.equal('Internal Server Error');
        queryStub.restore();
    });
});
