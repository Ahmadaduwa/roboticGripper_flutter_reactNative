import React, { useEffect, useState } from 'react';
import { View, Text, ActivityIndicator, StyleSheet, TouchableOpacity } from 'react-native';
import { useRobot } from '../features/RobotContext';
import { colors } from '../theme/colors';
import { api } from '../api/api';
import { WifiOff, RotateCw } from 'lucide-react-native';

export const SplashScreen = ({ navigation }) => {
    const { syncPatterns } = useRobot();
    const [status, setStatus] = useState('Checking connection...');
    const [hasError, setHasError] = useState(false);

    const initialize = async () => {
        setStatus('Connecting to Simulation...');
        setHasError(false);

        // 1. Check Connectivity (Health)
        const isOnline = await api.checkBackendAvailable();
        if (!isOnline) {
            setHasError(true);
            setStatus('Cannot connect to Simulation Backend.\nPlease ensure simulation.py is running.');
            return;
        }

        // 2. Sync Data
        setStatus('Syncing Database...');
        await syncPatterns();

        // 3. Navigate
        navigation.replace('Main');
    };

    useEffect(() => {
        initialize();
    }, []);

    return (
        <View style={styles.container}>
            {hasError ? (
                <View style={styles.center}>
                    <WifiOff size={80} color={colors.danger} />
                    <Text style={styles.title}>Connection Failed</Text>
                    <Text style={styles.errorText}>{status}</Text>
                    <TouchableOpacity style={styles.button} onPress={initialize}>
                        <RotateCw size={20} color="white" style={{ marginRight: 8 }} />
                        <Text style={styles.buttonText}>Retry Connection</Text>
                    </TouchableOpacity>
                </View>
            ) : (
                <View style={styles.center}>
                    <ActivityIndicator size="large" color={colors.text} />
                    <Text style={styles.statusText}>{status}</Text>
                </View>
            )}
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: colors.primary,
        justifyContent: 'center',
        alignItems: 'center',
    },
    center: {
        alignItems: 'center',
        padding: 32,
    },
    title: {
        fontSize: 28,
        fontWeight: 'bold',
        color: colors.text,
        marginTop: 24,
        marginBottom: 16,
    },
    errorText: {
        color: colors.textSecondary,
        textAlign: 'center',
        marginBottom: 32,
        fontSize: 16,
    },
    statusText: {
        color: colors.text,
        marginTop: 32,
        fontSize: 18,
        fontWeight: '500',
    },
    button: {
        flexDirection: 'row',
        backgroundColor: 'rgba(255,255,255,0.2)',
        paddingVertical: 16,
        paddingHorizontal: 32,
        borderRadius: 8,
        alignItems: 'center',
    },
    buttonText: {
        color: 'white',
        fontWeight: 'bold',
        fontSize: 16,
    }
});
