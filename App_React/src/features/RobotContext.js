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
                // 2. Update Local State (In-Memory)
                // In a real app we might merge, but strict sync means backend is truth.
                setPatterns(remotePatterns);
                // Persist for offline cache (though mode is online-only)
                await AsyncStorage.setItem('patterns', JSON.stringify(remotePatterns));
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
        if (pattern.id) {
            const idx = updatedList.findIndex(p => p.id === pattern.id);
            if (idx >= 0) updatedList[idx] = pattern;
            else updatedList.push(pattern);
        } else {
            // New pattern (no ID yet), relying on Name or Push to assign ID? 
            // Backend sync push uses ID or Name. 
            // We'll push it, then pull to get ID.
            updatedList.push(pattern);
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
