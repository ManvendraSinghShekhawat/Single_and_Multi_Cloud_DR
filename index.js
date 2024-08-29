const express = require('express');
const { Client } = require('pg');
const path = require('path');

const app = express();
const port = 3000;

const primaryConfig = {
    host: 'terraform-20240807030842941700000005.c3om60ww0jqb.eu-north-1.rds.amazonaws.com',
    port: 5432,
    database: 'mydatabase',
    user: 'dbadmin',
    password: 'Y}Phs<gYU!fRbT1}',
    ssl: {
        rejectUnauthorized: false // Set to true for strict SSL checks
    }
};

const secondaryConfig = {
    user: 'dbadmin',
    host: 'terraform-20240807030844012200000003.cjg4880oivyw.eu-west-1.rds.amazonaws.com',
    database: 'mydatabase',
    password: 'Y}Phs<gYU!fRbT1}',
    port: 5432,
    ssl: {
        rejectUnauthorized: false // Set to true for strict SSL checks
    }
};

let activeDb = 'Primary';

const connectWithTimeout = (config, timeout = 5000) => {
    return new Promise((resolve, reject) => {
        const client = new Client(config);
        let timer = setTimeout(() => {
            client.end();
            reject(new Error('Connection timeout'));
        }, timeout);

        client.connect()
            .then(() => {
                clearTimeout(timer);
                resolve(client);
            })
            .catch((err) => {
                clearTimeout(timer);
                reject(err);
            });
    });
};

async function connectToDatabase() {
    try {
        console.log('Attempting to connect to Primary DB...');
        const client = await connectWithTimeout(primaryConfig);
        activeDb = 'Primary';
        console.log(`Connected to Primary Database`);
        return client;
    } catch (primaryError) {
        console.error(`Primary DB connection failed: ${primaryError.message}`);
        console.log('Attempting to connect to Secondary DB...');
        try {
            const client = await connectWithTimeout(secondaryConfig);
            activeDb = 'Secondary';
            console.log(`Connected to Secondary Database`);
            return client;
        } catch (secondaryError) {
            console.error(`Secondary DB connection failed: ${secondaryError.message}`);
            throw new Error('Both primary and secondary RDS instances are down.');
        }
    }
}

let dbClient;
(async () => {
    try {
        dbClient = await connectToDatabase();
    } catch (error) {
        console.error(`Failed to connect to any database: ${error.message}`);
        process.exit(1); // Exit the process if both DBs fail
    }
})();

app.use(express.static(path.join(__dirname, 'public')));

app.get('/status', async (req, res) => {
    try {
        await dbClient.query('SELECT NOW()');
        res.json({ status: 'connected', activeDb });
    } catch (error) {
        res.status(500).json({ status: 'error', message: error.message });
    }
});

app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});
