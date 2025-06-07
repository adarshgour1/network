-- Network Schema Definition
CREATE SCHEMA IF NOT EXISTS network;

-- Device Table
CREATE TABLE IF NOT EXISTS network.devices (
    id SERIAL PRIMARY KEY,
    hostname TEXT NOT NULL UNIQUE
);

-- Interfaces Table
CREATE TABLE IF NOT EXISTS network.interfaces (
    id SERIAL PRIMARY KEY,
    ipaddr INET NOT NULL,
    device_id INTEGER NOT NULL REFERENCES network.devices(id) ON DELETE CASCADE,
    UNIQUE(ipaddr, device_id)
);

-- Metrics Definition Table
CREATE TABLE IF NOT EXISTS network.metric (
    id SERIAL PRIMARY KEY,
    metric_name TEXT NOT NULL UNIQUE,
    data_type TEXT NOT NULL DEFAULT 'DOUBLE PRECISION' CHECK (data_type IN ('INTEGER', 'DOUBLE PRECISION', 'TEXT', 'BOOLEAN', 'TIMESTAMP'))
);

-- Insert default metrics
INSERT INTO network.metric (id, metric_name, data_type) VALUES 
    (1, 'rtt', 'DOUBLE PRECISION'),
    (2, 'success_rate', 'DOUBLE PRECISION'),
    (3, 'packet_loss', 'INTEGER'),
    (4, 'jitter', 'DOUBLE PRECISION')
ON CONFLICT DO NOTHING;

-- Collection Schema Definition
CREATE SCHEMA IF NOT EXISTS collection;

-- Function to create a new device collection table dynamically
CREATE OR REPLACE FUNCTION collection.create_device_table(hostname TEXT)
RETURNS VOID AS $$
DECLARE
    table_name TEXT;
    create_stmt TEXT := '';
    metric_record RECORD;
    column_definitions TEXT := '';
BEGIN
    -- Use the hostname as the table name, but replace hyphens with underscores for valid SQL identifiers
    table_name := 'collection.' || replace(hostname, '-', '_');
    
    -- Check if table already exists, create if it doesn't
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'collection' 
        AND tablename = replace(hostname, '-', '_')
    ) THEN
        -- Start with common columns
        create_stmt := 'CREATE TABLE ' || table_name || ' (
                time TIMESTAMPTZ NOT NULL,
                interface_id INTEGER NOT NULL REFERENCES network.interfaces(id) ON DELETE CASCADE,';
        
        -- Add each metric as a separate column with its specific data type
        FOR metric_record IN SELECT id, metric_name, data_type FROM network.metric ORDER BY id LOOP
            column_definitions := column_definitions || 
                                 quote_ident(metric_record.metric_name) || 
                                 ' ' || metric_record.data_type || ' NULL,';
        END LOOP;
        
        -- Remove the trailing comma and add primary key
        create_stmt := create_stmt || column_definitions || 
                      'PRIMARY KEY (time, interface_id))';
        
        -- Execute the create table statement
        EXECUTE create_stmt;
        
        -- Convert to TimescaleDB hypertable for better time-series performance
        EXECUTE format('SELECT create_hypertable(%L, %L)', table_name, 'time');
        
        -- Create index for faster queries by interface_id
        EXECUTE format('CREATE INDEX ON %s (interface_id, time DESC)', table_name);
        
        -- Create indexes for each metric column for faster queries
        FOR metric_record IN SELECT metric_name FROM network.metric LOOP
            EXECUTE format('CREATE INDEX ON %s (%I)', 
                          table_name, 
                          metric_record.metric_name);
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically create collection tables when new devices are added
CREATE OR REPLACE FUNCTION collection.create_device_table_trigger()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM collection.create_device_table(NEW.hostname);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on devices table
CREATE TRIGGER device_table_creation_trigger
AFTER INSERT ON network.devices
FOR EACH ROW
EXECUTE FUNCTION collection.create_device_table_trigger();

-- Comment explaining the system
COMMENT ON SCHEMA network IS 'Contains network device configuration and metadata';
COMMENT ON SCHEMA collection IS 'Contains time-series data collected from network devices';
