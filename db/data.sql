-- Sample data for network schema
-- Add devices
INSERT INTO network.devices (hostname) VALUES
    ('router-core-01'),
    ('switch-access-01'),
    ('switch-access-02'),
    ('firewall-edge-01'),
    ('server-app-01');

-- Add interfaces for router-core-01
INSERT INTO network.interfaces (ipaddr, device_id) 
    SELECT '192.168.1.1'::inet, id FROM network.devices WHERE hostname = 'router-core-01'
    UNION ALL
    SELECT '10.0.0.1'::inet, id FROM network.devices WHERE hostname = 'router-core-01';

-- Add interfaces for switch-access-01
INSERT INTO network.interfaces (ipaddr, device_id) 
    SELECT '192.168.1.2'::inet, id FROM network.devices WHERE hostname = 'switch-access-01'
    UNION ALL
    SELECT '10.0.0.2'::inet, id FROM network.devices WHERE hostname = 'switch-access-01';

-- Add interfaces for switch-access-02
INSERT INTO network.interfaces (ipaddr, device_id) 
    SELECT '192.168.1.3'::inet, id FROM network.devices WHERE hostname = 'switch-access-02'
    UNION ALL
    SELECT '10.0.0.3'::inet, id FROM network.devices WHERE hostname = 'switch-access-02';

-- Add interfaces for firewall-edge-01
INSERT INTO network.interfaces (ipaddr, device_id) 
    SELECT '192.168.1.254'::inet, id FROM network.devices WHERE hostname = 'firewall-edge-01'
    UNION ALL
    SELECT '203.0.113.1'::inet, id FROM network.devices WHERE hostname = 'firewall-edge-01';

-- Add interfaces for server-app-01
INSERT INTO network.interfaces (ipaddr, device_id) 
    SELECT '192.168.2.10'::inet, id FROM network.devices WHERE hostname = 'server-app-01';

-- Verify that collection tables were created (the trigger should have created them)
SELECT tablename FROM pg_tables WHERE schemaname = 'collection';

-- You can uncomment and run this to see all devices and their interfaces
-- SELECT d.hostname, i.ipaddr 
-- FROM network.devices d 
-- JOIN network.interfaces i ON d.id = i.device_id 
-- ORDER BY d.hostname, i.ipaddr;