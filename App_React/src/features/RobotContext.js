import React, { createContext, useState, useEffect, useContext } from 'react';
import { api } from '../api/api';
import AsyncStorage from '@react-native-async-storage/async-storage';

const RobotContext = createContext();

export const RobotProvider = ({ children }) => {
    const [sensorData, setSensorData] = useState(null);
    const [isConnected, setIsConnected] = useState(false);
    const [patterns, setPatterns] = useState([]);

    // Polling Sensor Data
    useEffect(() => {
        const interval = setInterval(async () => {
            const data = await api.getSensorData();
            if (data) {
                setSensorData(data);
                setIsConnected(true);
            } else {
                setIsConnected(false);
            }
        }, 500);
        return () => clearInterval(interval);
    }, []);

    // Initial Sync Logic
    const syncPatterns = async () => {
        try {
            // 1. Pull from Backend
            const remotePatterns = await api.pullPatterns();
            if (remotePatterns) {
                // Ensure steps have proper structure and handle null values
                const normalizedPatterns = (remotePatterns || []).map(p => ({
                    id: p.id,
                    name: p.name || '',
                    description: p.description || '',
                    steps: (p.steps || []).map((s, index) => ({
                        step_order: s.step_order !== undefined ? s.step_order : index,
                        action_type: s.action_type || 'wait',
                        params: s.params ? { ...s.params } : {},
                    })),
                }));
                
                // 2. Update Local State (In-Memory)
                // In a real app we might merge, but strict sync means backend is truth.
                setPatterns(normalizedPatterns);
                // Persist for offline cache (though mode is online-only)
                await AsyncStorage.setItem('patterns', JSON.stringify(normalizedPatterns));
                return true;
            }
            return false;
        } catch (e) {
            console.error("Sync failed", e);
            return false;
        }
    };

    // Load from local storage (backup)
    const loadLocalPatterns = async () => {
        try {
            const json = await AsyncStorage.getItem('patterns');
            if (json) setPatterns(JSON.parse(json));
        } catch (e) { }
    };

    // CRUD for Patterns
    const savePattern = async (pattern) => {
        // Structure match: { name, description, steps: [...] }
        // We construct strictly what backend expects for "Push".

        // 1. Create a temporary list including the new/updated pattern
        let updatedList = [...patterns];
        
        // Format pattern with step_order for backend compatibility
        const formattedPattern = {
            name: pattern.name,
            description: pattern.description || '',
            steps: (pattern.steps || []).map((step, index) => ({
                step_order: index,
                action_type: step.action_type,
                params: step.params || {},
            })),
        };
        
        // Only include id if it exists
        if (pattern.id) {
            formattedPattern.id = pattern.id;
        }
        
        if (pattern.id) {
            const idx = updatedList.findIndex(p => p.id === pattern.id);
            if (idx >= 0) updatedList[idx] = formattedPattern;
            else updatedList.push(formattedPattern);
        } else {
            // New pattern (no ID yet), relying on Name or Push to assign ID? 
            // Backend sync push uses ID or Name. 
            // We'll push it, then pull to get ID.
            updatedList.push(formattedPattern);
        }

        // 2. Push to backend
        const success = await api.pushPatterns(updatedList);

        // 3. Pull to reconcile
        if (success) {
            await syncPatterns();
        }
        return success;
    };

    const deletePattern = async (id) => {
        // 1. Delete on backend
        await api.deletePattern(id);
        // 2. Sync
        await syncPatterns();
    };

    return (
        <RobotContext.Provider value={{
            sensorData,
            isConnected,
            patterns,
            syncPatterns,
            loadLocalPatterns,
            savePattern,
            deletePattern
        }}>
            {children}
        </RobotContext.Provider>
    );
};

export const useRobot = () => useContext(RobotContext);
