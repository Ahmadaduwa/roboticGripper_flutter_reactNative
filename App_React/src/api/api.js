import axios from 'axios';
import { Platform } from 'react-native';

// Detect Environment
const getBaseUrl = () => {
    // For Web, localhost is fine.
    // For Android Emulator, 10.0.2.2 is localhost.
    // For Real Device, you'd need the actual IP. 
    // We'll stick to Emulator/Web defaults for this simulation context.
    if (Platform.OS === 'android') {
        return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
};

let API_URL = getBaseUrl();
const TIMEOUT = 5000;

const client = axios.create({
    baseURL: API_URL,
    timeout: TIMEOUT,
    headers: {
        'Content-Type': 'application/json',
    },
});

export const setApiBaseUrl = (url) => {
    API_URL = url;
    client.defaults.baseURL = url;
};

export const getApiBaseUrl = () => API_URL;


export const api = {
    // 0. Health Check
    checkBackendAvailable: async () => {
        try {
            const response = await client.get('/health');
            return response.status === 200;
        } catch (e) {
            return false;
        }
    },

    // 1. Get Sensor Data
    getSensorData: async () => {
        try {
            const response = await client.get('/data');
            return response.data;
        } catch (e) {
            return null;
        }
    },

    // 2. Manual Gripper/Joint Control
    // Note: App sends 'angle', 'max_force', 'switch_on' to /api/robot/gripper
    sendGripperCommand: async ({ angle, maxForce, switchOn }) => {
        try {
            const body = {
                angle: Math.round(angle),
                max_force: maxForce,
                switch_on: switchOn,
            };
            const response = await client.post('/api/robot/gripper', body);
            return response.status === 200;
        } catch (e) {
            return false;
        }
    },

    // Also need manual move for joints if Dashboard sends it?
    // Flutter implementation didn't explicitly expose manual joint move in RobotProvider, 
    // but let's include it just in case Control Screen needs it.
    manualMove: async (joints) => {
        try {
            const response = await client.post('/api/robot/manual-move', joints);
            return response.status === 200;
        } catch (e) {
            return false;
        }
    },

    // Control Gripper - restore saved state
    controlGripper: async (state) => {
        try {
            const body = {
                angle: Math.round(state.angle),
                max_force: state.max_force,
                switch_on: state.switch_on,
            };
            const response = await client.post('/api/robot/gripper', body);
            return response.status === 200;
        } catch (e) {
            // Handle 423 Locked errors gracefully (sequence still running)
            if (e.response && e.response.status === 423) {
                console.warn('Robot locked (sequence still running):', e.response.statusText);
                return false;
            }
            console.error('Control gripper error:', e);
            return false;
        }
    },

    // 6. Auto Run Start
    startAutoRun: async ({ patternId, cycles, maxForce, filename }) => {
        try {
            const body = {
                pattern_id: patternId,
                cycles: cycles,
                max_force: maxForce,
                filename: filename || 'run.csv',
            };
            const response = await client.post('/auto-run/start', body);
            return response.status === 200;
        } catch (e) {
            return false;
        }
    },

    // Auto Run Stop
    stopAutoRun: async () => {
        try {
            const response = await client.post('/auto-run/stop');
            return response.status === 200;
        } catch (e) {
            return false;
        }
    },

    // 7. Get All Patterns
    getPatterns: async () => {
        try {
            const response = await client.get('/api/patterns');
            return response.data || [];
        } catch (e) {
            return [];
        }
    },

    // 8. Get Single Pattern
    getPattern: async (id) => {
        try {
            const response = await client.get(`/api/patterns/${id}`);
            return response.data;
        } catch (e) {
            return null;
        }
    },

    // 9. Delete Pattern
    deletePattern: async (id) => {
        try {
            const response = await client.delete(`/api/patterns/${id}`);
            return response.status === 200;
        } catch (e) {
            return false;
        }
    },

    // 13. Execute Sequence
    executeSequence: async ({ steps, maxForce, gripperAngle, isOn, patternName }) => {
        try {
            const body = {
                pattern_name: patternName || 'Untitled',
                max_force: maxForce,
                gripper_angle: gripperAngle,
                is_on: isOn,
                steps: steps,
            };
            const response = await client.post('/api/teach/execute-sequence', body);
            return response.status === 200;
        } catch (e) {
            return false;
        }
    },

    stopSequence: async () => {
        try {
            const response = await client.post('/api/teach/stop');
            return response.status === 200;
        } catch (e) {
            return false;
        }
    },

    // 14. Sync Pull
    pullPatterns: async () => {
        try {
            const response = await client.get('/api/sync/patterns');
            if (response.data && response.data.patterns) {
                return response.data.patterns;
            }
            return [];
        } catch (e) {
            return [];
        }
    },

    // 15. Sync Push
    pushPatterns: async (patterns) => {
        try {
            const body = { patterns: patterns };
            const response = await client.post('/api/sync/patterns', body);
            return response.status === 200;
        } catch (e) {
            return false;
        }
    },

    // 16. Get History
    getRunHistory: async () => {
        try {
            const response = await client.get('/api/history');
            return response.data || [];
        } catch (e) {
            return [];
        }
    },

    // 17. Delete History
    deleteRunHistory: async (idOrFilename) => {
        try {
            console.log("Deleting history with:", idOrFilename);
            const response = await client.delete(`/api/history/${idOrFilename}`);
            console.log("Delete response status:", response.status);
            return response.status === 200;
        } catch (e) {
            console.error('Delete history error:', e);
            return false;
        }
    },

    // Download URL builder
    getDownloadUrl: (filename) => {
        return `${API_URL}/api/logs/download/${filename}`;
    }
};
