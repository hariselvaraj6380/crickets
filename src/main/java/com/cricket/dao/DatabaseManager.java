package com.cricket.dao;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.logging.Level;
import java.util.logging.Logger;

public class DatabaseManager {
    private static final Logger LOGGER = Logger.getLogger(DatabaseManager.class.getName());

    // Primary MySQL configuration
    private static final String MYSQL_URL = "jdbc:mysql://localhost:3306/cricket_db?createDatabaseIfNotExist=true&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    private static final String MYSQL_USER = "root";
    private static final String MYSQL_PASSWORD = "root";

    // Fallback H2 in-memory configuration
    private static final String H2_URL = "jdbc:h2:mem:cricketdb;DB_CLOSE_DELAY=-1;MODE=MySQL";
    private static final String H2_USER = "sa";
    private static final String H2_PASSWORD = "";

    private static boolean useH2 = false;
    private static boolean initialized = false;

    public static synchronized Connection getConnection() throws SQLException {
        Connection conn;
        if (useH2) {
            conn = DriverManager.getConnection(H2_URL, H2_USER, H2_PASSWORD);
        } else {
            try {
                conn = DriverManager.getConnection(MYSQL_URL, MYSQL_USER, MYSQL_PASSWORD);
            } catch (SQLException e) {
                LOGGER.log(Level.WARNING, "Primary MySQL connection failed. Switching to H2 fallback mode: {0}", e.getMessage());
                useH2 = true;
                conn = DriverManager.getConnection(H2_URL, H2_USER, H2_PASSWORD);
            }
        }

        if (!initialized) {
            initialized = true;
            initializeSchema(conn);
        }
        return conn;
    }

    public static synchronized void initializeDatabase() {
        try (Connection conn = getConnection()) {
            // getConnection already triggers initializeSchema if needed
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to initialize database: {0}", e.getMessage());
        }
    }

    private static void initializeSchema(Connection conn) {
        try (Statement stmt = conn.createStatement()) {
            InputStream is = DatabaseManager.class.getResourceAsStream("/schema.sql");
            if (is == null) {
                LOGGER.warning("schema.sql not found in resources");
                return;
            }

            BufferedReader reader = new BufferedReader(new InputStreamReader(is));
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.trim().startsWith("--") || line.trim().isEmpty()) {
                    continue;
                }
                sb.append(line).append(" ");
                if (line.trim().endsWith(";")) {
                    String sql = sb.toString().replace(";", "").trim();
                    try {
                        stmt.execute(sql);
                    } catch (SQLException ex) {
                        LOGGER.log(Level.FINE, "SQL init notice: {0}", ex.getMessage());
                    }
                    sb.setLength(0);
                }
            }
            LOGGER.info("Database schema initialized successfully (" + (useH2 ? "H2 Embedded Mode" : "MySQL Mode") + ")");
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Error reading schema.sql: {0}", e.getMessage());
        }
    }

    public static boolean isUsingH2() {
        return useH2;
    }
}
