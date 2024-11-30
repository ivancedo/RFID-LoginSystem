const http = require('http');
const mysql = require('mysql2');
const url = require('url'); // Required to process query parameters

// Database connection configuration
//
// This block configures and establishes the connection to the MySQL database.
const connection = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '1234',
    database: 'PBE',
});

// Verify the database connection
//
// Logs a success message or an error if the connection fails.
connection.connect((err) => {
    if (err) {
        console.error('Database connection error: ' + err.stack);
        return;
    }
    console.log('Connected to the database with ID ' + connection.threadId);
});

// Manage user sessions
//
// Stores active user sessions and their last activity timestamps.
const userSessions = {};
const SESSION_TIMEOUT = 2 * 60 * 1000; // Session timeout in milliseconds (2 minutes)

// Create the HTTP server
//
// This block initializes an HTTP server and handles incoming requests.
const server = http.createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Access-Control-Allow-Origin', '*');

    const parsedUrl = url.parse(req.url, true); // Parse the URL

    // Handle user authentication
    if (req.method === 'GET' && parsedUrl.pathname === '/authenticate') {
        const { uid } = parsedUrl.query;

        if (!uid) {
            res.statusCode = 400;
            res.end(JSON.stringify({ error: 'UID is required' }));
            return;
        }

        connection.query(
            'SELECT name FROM students WHERE student_id = ?',
            [uid],
            (err, results) => {
                if (err) {
                    res.statusCode = 500;
                    res.end(JSON.stringify({ error: 'srv: Database query error' }));
                } else if (results.length === 0) {
                    res.statusCode = 401;
                    res.end(JSON.stringify({ error: 'Invalid UID' }));
                } else {
                    userSessions[uid] = {
                        name: results[0].name,
                        lastActivity: Date.now()
                    };
                    res.statusCode = 200;
                    res.end(JSON.stringify({ name: results[0].name }));
                }
            }
        );

    // Handle table queries
    } else if (req.method === 'GET' && parsedUrl.pathname === '/query') {
        const { table, limit, ...filters } = parsedUrl.query;
        const uid = Object.keys(userSessions).find((uid) => userSessions[uid]);

        if (!uid) {
            res.statusCode = 600;
            res.end(JSON.stringify({ error: 'Session not started or expired' }));
            return;
        }

        userSessions[uid].lastActivity = Date.now();

        const validTables = {
            tasks: ['date', 'subject', 'name'],
            timetables: ['day', 'hour', 'subject', 'room'],
            marks: ['subject', 'name', 'marks']
        };

        if (!table || !validTables[table]) {
            res.statusCode = 400;
            res.end(JSON.stringify({ error: 'Invalid or required table' }));
            return;
        }

        const selectedColumns = validTables[table].join(', ');
        let query = `SELECT ${selectedColumns} FROM ${table} WHERE student_id = ?`;
        const params = [uid];

        if (Object.keys(filters).length > 0) {
            const conditions = [];
            const opMap = {
                gte: '>=',
                gt: '>',
                lte: '<=',
                lt: '<',
                eq: '='
            };

            for (const [key, value] of Object.entries(filters)) {
                if (key.includes('[') && key.includes(']')) {
                    const field = key.split('[')[0];
                    const modifier = key.match(/\[(.+)\]/)[1];
                    const op = opMap[modifier];

                    if (op) {
                        conditions.push(`${field} ${op} ?`);
                        params.push(value);
                    }
                } else {
                    conditions.push(`${key} = ?`);
                    params.push(value);
                }
            }

            query += ' AND ' + conditions.join(' AND ');
        }

        if (limit) {
            query += ' LIMIT ?';
            params.push(parseInt(limit, 10));
        }

        connection.query(query, params, (err, results) => {
            if (err) {
                res.statusCode = 500;
                res.end(JSON.stringify({ error: 'Database query error' }));
            } else {
                res.statusCode = 200;
                res.end(JSON.stringify(results));
            }
        });

    // Handle user logout
    } else if (req.method === 'GET' && parsedUrl.pathname === '/logout') {
        const uid = Object.keys(userSessions).find((uid) => userSessions[uid]);

        if (!uid) {
            res.statusCode = 400;
            res.end(JSON.stringify({ error: 'Session not started' }));
            return;
        }

        delete userSessions[uid];
        res.statusCode = 200;
        res.end(JSON.stringify({ message: 'Session successfully closed' }));

    // Handle unknown routes
    } else {
        res.statusCode = 404;
        res.end(JSON.stringify({ error: 'Route not found' }));
    }
});

// Timer to manage session expiration
//
// Periodically checks and removes inactive user sessions.
setInterval(() => {
    const now = Date.now();
    for (const uid in userSessions) {
        if (now - userSessions[uid].lastActivity > SESSION_TIMEOUT) {
            console.log(`User session ${uid} has expired`);
            delete userSessions[uid];
        }
    }
}, 60 * 1000);

// Start the server
//
// The server listens on the specified port and logs the address.
const PORT = 3000;
const HOST = 'localhost'

server.listen(PORT, HOST, () => {
    console.log(`Server listening at http://${HOST}:${PORT}`);
});
