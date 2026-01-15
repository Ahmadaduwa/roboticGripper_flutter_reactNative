import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, TextInput, Alert, ActivityIndicator, Modal, FlatList, Linking } from 'react-native';
import { useRobot } from '../features/RobotContext';
import { api } from '../api/api';
import { colors } from '../theme/colors';
import { Header } from '../components/Header';
import { Play, CheckCircle, FileText, Download, Trash2, ChevronDown, RefreshCw, XCircle, ChevronUp } from 'lucide-react-native';

import { useLanguage } from '../features/LanguageContext';

export const AutoRunScreen = () => {
    const { patterns } = useRobot();
    const { t } = useLanguage();

    // Config State
    const [selectedPattern, setSelectedPattern] = useState(null);
    const [cycles, setCycles] = useState('5');
    const [maxForce, setMaxForce] = useState('5.0');
    const [filename, setFilename] = useState('run_data.csv');
    const [isDropdownOpen, setIsDropdownOpen] = useState(false);

    // Status State
    const [isRunning, setIsRunning] = useState(false);
    const [history, setHistory] = useState([]);

    // Load initial pattern (if any)
    useEffect(() => {
        if (patterns.length > 0 && !selectedPattern) {
            setSelectedPattern(patterns[0]);
        }
    }, [patterns]);

    useEffect(() => {
        fetchHistory();
    }, []);

    const fetchHistory = async () => {
        try {
            const data = await api.getRunHistory();
            if (data) setHistory(data);
        } catch (e) {
            console.log("History error", e);
        }
    };

    const handleStart = async () => {
        if (!selectedPattern) return Alert.alert("Error", "Please select a pattern");
        if (isRunning) return handleStop();

        setIsRunning(true);

        // Correctly mapping keys to api.js expected function arguments
        const success = await api.startAutoRun({
            patternId: selectedPattern.id,
            cycles: parseInt(cycles),
            maxForce: parseFloat(maxForce),
            filename: filename
        });

        if (success) {
            Alert.alert("Started", "Auto Run Started Successfully");
            // Poll for completion or updates in real app
            setTimeout(fetchHistory, 5000); // Simple refresh after 5s
        } else {
            setIsRunning(false);
            Alert.alert("Error", "Failed to start. Check connection or parameters.");
        }
    };

    const handleStop = async () => {
        await api.stopAutoRun();
        setIsRunning(false);
        Alert.alert("Stopped", "Auto Run Stopped");
    };

    const handleDeleteLog = async (filename) => {
        // Optimistic delete
        setHistory(prev => prev.filter(h => h.filename !== filename));
    };

    const downloadLog = async (filename) => {
        const url = api.getDownloadUrl(filename);
        try {
            const supported = await Linking.canOpenURL(url);
            if (supported) {
                await Linking.openURL(url);
            } else {
                Alert.alert("Error", "Cannot open download link");
            }
        } catch (e) {
            Alert.alert("Error", "Download failed");
        }
    };

    return (
        <View style={styles.container}>
            <Header
                title={t('autoRun')}
                rightIcon={
                    <TouchableOpacity onPress={fetchHistory}>
                        <RefreshCw color="white" size={24} />
                    </TouchableOpacity>
                }
            />

            <ScrollView contentContainerStyle={styles.content}>

                {/* 1. System Status Card */}
                <View style={styles.statusCard}>
                    <View style={styles.statusIconContainer}>
                        {isRunning ?
                            <ActivityIndicator size="large" color={colors.primary} /> :
                            <CheckCircle size={48} color="#29B6F6" fill="white" />
                        }
                    </View>
                    <View>
                        <Text style={styles.statusLabel}>{t('systemStatus')}</Text>
                        <Text style={[styles.statusMain, isRunning && { color: colors.success }]}>
                            {isRunning ? t('running') : t('systemReady')}
                        </Text>
                    </View>
                </View>

                {/* 2. Configuration */}
                <Text style={styles.sectionHeader}>{t('runConfiguration').toUpperCase()}</Text>
                <View style={styles.configCard}>

                    {/* Pattern Dropdown Trigger */}
                    <TouchableOpacity style={styles.row} onPress={() => setIsDropdownOpen(true)}>
                        <Text style={styles.rowLabel}>{t('selectPattern')}</Text>
                        <View style={styles.rowValueContainer}>
                            <Text style={styles.rowValueText}>{selectedPattern?.name || t('selectPattern')}</Text>
                            <ChevronDown size={16} color="#757575" />
                        </View>
                    </TouchableOpacity>
                    <View style={styles.divider} />

                    {/* Cycles */}
                    <View style={styles.row}>
                        <Text style={styles.rowLabel}>{t('cycleCount')}</Text>
                        <TextInput
                            style={styles.inputBlue}
                            value={cycles}
                            onChangeText={setCycles}
                            keyboardType="numeric"
                        />
                    </View>
                    <View style={styles.divider} />

                    {/* Force Limit */}
                    <View style={styles.row}>
                        <Text style={styles.rowLabel}>{t('maxForceLimit')} (N)</Text>
                        <TextInput
                            style={styles.inputBlue}
                            value={maxForce}
                            onChangeText={setMaxForce}
                            keyboardType="numeric"
                        />
                    </View>
                    <View style={styles.divider} />

                    {/* Filename */}
                    <View style={styles.row}>
                        <Text style={styles.rowLabel}>{t('logFilename')}</Text>
                        <TextInput
                            style={styles.inputNormal}
                            value={filename}
                            onChangeText={setFilename}
                        />
                    </View>
                </View>

                {/* 3. Action Button */}
                <TouchableOpacity
                    style={[styles.actionBtn, isRunning && { backgroundColor: colors.danger }]}
                    onPress={handleStart}
                >
                    {isRunning ? <XCircle color="white" fill="white" size={24} style={{ marginRight: 8 }} /> :
                        <Play color="white" fill="white" size={24} style={{ marginRight: 8 }} />}
                    <Text style={styles.actionBtnText}>
                        {isRunning ? t('stopAutoRun') : t('startAutoRun')}
                    </Text>
                </TouchableOpacity>

                {/* 4. Recent Logs */}
                <Text style={[styles.sectionHeader, { marginTop: 32 }]}>{t('executionLogs').toUpperCase()}</Text>

                {history.map((log, index) => (
                    <View key={index} style={styles.logCard}>
                        <View style={styles.fileIcon}>
                            <FileText size={24} color="#0288D1" />
                        </View>

                        <View style={{ flex: 1, paddingHorizontal: 12 }}>
                            <Text style={styles.logName}>{log.filename}</Text>
                            <Text style={styles.logMeta}>
                                Pattern:{log.pattern_id} • {t('status')}:{log.status} • {new Date(log.created_at).toLocaleTimeString()}
                            </Text>
                        </View>

                        <View style={styles.logActions}>
                            <TouchableOpacity onPress={() => downloadLog(log.filename)}>
                                <Download size={20} color="#616161" />
                            </TouchableOpacity>
                            <TouchableOpacity onPress={() => handleDeleteLog(log.filename)}>
                                <Trash2 size={20} color="#E53935" />
                            </TouchableOpacity>
                        </View>
                    </View>
                ))}

                <View style={{ height: 40 }} />
            </ScrollView>

            {/* Modal for Dropdown */}
            <Modal
                transparent={true}
                visible={isDropdownOpen}
                animationType="fade"
                onRequestClose={() => setIsDropdownOpen(false)}
            >
                <TouchableOpacity style={styles.modalOverlay} activeOpacity={1} onPress={() => setIsDropdownOpen(false)}>
                    <View style={styles.dropdownModal}>
                        <Text style={styles.dropdownHeader}>{t('selectPattern')}</Text>
                        <FlatList
                            data={patterns}
                            keyExtractor={(item) => item.id.toString()}
                            renderItem={({ item }) => (
                                <TouchableOpacity
                                    style={styles.dropdownItem}
                                    onPress={() => {
                                        setSelectedPattern(item);
                                        setIsDropdownOpen(false);
                                    }}
                                >
                                    <Text style={[styles.dropdownItemText, selectedPattern?.id === item.id && { color: colors.primary, fontWeight: 'bold' }]}>
                                        {item.name} (ID: {item.id})
                                    </Text>
                                    {selectedPattern?.id === item.id && <CheckCircle size={16} color={colors.primary} />}
                                </TouchableOpacity>
                            )}
                        />
                        <TouchableOpacity style={styles.closeBtn} onPress={() => setIsDropdownOpen(false)}>
                            <Text style={{ color: 'white', fontWeight: 'bold' }}>{t('cancel')}</Text>
                        </TouchableOpacity>
                    </View>
                </TouchableOpacity>
            </Modal>
        </View>
    );
};

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: '#F5F5F5' },
    content: { padding: 16 },

    // Status Card
    statusCard: {
        backgroundColor: 'white',
        borderRadius: 16,
        padding: 20,
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: 24,
        elevation: 2,
        borderWidth: 1,
        borderColor: '#EEEEEE'
    },
    statusIconContainer: { marginRight: 16 },
    statusLabel: { fontSize: 10, color: '#9E9E9E', fontWeight: 'bold', marginBottom: 4 },
    statusMain: { fontSize: 22, color: '#212121', fontWeight: 'bold' },

    // Config
    sectionHeader: { fontSize: 12, fontWeight: 'bold', color: '#9E9E9E', marginBottom: 12, letterSpacing: 1 },
    configCard: {
        backgroundColor: 'white',
        borderRadius: 16,
        paddingHorizontal: 20,
        paddingVertical: 8,
        marginBottom: 24,
        elevation: 2
    },
    row: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingVertical: 16
    },
    rowLabel: { fontSize: 16, fontWeight: '600', color: '#424242' },
    rowValueContainer: { flexDirection: 'row', alignItems: 'center', gap: 8 },
    rowValueText: { fontSize: 16, fontWeight: 'bold', color: '#212121' },
    inputBlue: { fontSize: 18, fontWeight: 'bold', color: '#0D47A1', textAlign: 'right', minWidth: 50 },
    inputNormal: { fontSize: 16, fontWeight: 'bold', color: '#212121', textAlign: 'right', minWidth: 100 },
    divider: { height: 1, backgroundColor: '#F5F5F5', width: '100%' },

    // Action Button
    actionBtn: {
        backgroundColor: colors.primary,
        borderRadius: 12,
        paddingVertical: 18,
        flexDirection: 'row',
        justifyContent: 'center',
        alignItems: 'center',
        elevation: 4
    },
    actionBtnText: { color: 'white', fontSize: 18, fontWeight: 'bold' },

    // Logs
    logCard: {
        backgroundColor: 'white',
        borderRadius: 12,
        padding: 16,
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: 12,
        elevation: 1
    },
    fileIcon: {
        width: 40, height: 40,
        borderRadius: 20,
        backgroundColor: '#E3F2FD',
        justifyContent: 'center', alignItems: 'center'
    },
    logName: { fontSize: 16, fontWeight: 'bold', color: '#212121' },
    logMeta: { fontSize: 12, color: '#757575', marginTop: 2 },
    logActions: { flexDirection: 'row', gap: 16 },

    // Modal
    modalOverlay: { flex: 1, backgroundColor: 'rgba(0,0,0,0.5)', justifyContent: 'center', alignItems: 'center', padding: 20 },
    dropdownModal: { backgroundColor: 'white', width: '100%', maxHeight: '50%', borderRadius: 16, padding: 16 },
    dropdownHeader: { fontSize: 18, fontWeight: 'bold', marginBottom: 16, color: '#424242' },
    dropdownItem: { paddingVertical: 12, borderBottomWidth: 1, borderColor: '#EEEEEE', flexDirection: 'row', justifyContent: 'space-between' },
    dropdownItemText: { fontSize: 16, color: '#616161' },
    closeBtn: { backgroundColor: colors.primary, padding: 12, borderRadius: 8, alignItems: 'center', marginTop: 16 }
});
