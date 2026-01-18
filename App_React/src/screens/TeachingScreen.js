import React, { useState, useRef } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, TextInput, Alert, Platform } from 'react-native';
import { useRobot } from '../features/RobotContext';
import { api } from '../api/api';
import { colors } from '../theme/colors';
import { Header } from '../components/Header';
import { Play, Trash2, Plus, Save, ArrowLeft, ArrowUp, ArrowDown, MapPin, Hand, Clock, RefreshCw, Square } from 'lucide-react-native';

import { useLanguage } from '../features/LanguageContext';

export const TeachingScreen = () => {
    const { patterns, savePattern, deletePattern, syncPatterns, sensorData } = useRobot();
    const { t } = useLanguage();
    const [selectedPattern, setSelectedPattern] = useState(null);
    const [patternName, setPatternName] = useState('');
    const [description, setDescription] = useState('');
    const [steps, setSteps] = useState([]);
    const [waitDuration, setWaitDuration] = useState('1.0');
    const [isExecuting, setIsExecuting] = useState(false);
    const [isGripMode, setIsGripMode] = useState(true);
    const [isSyncing, setIsSyncing] = useState(false);
    const [savedManualControlState, setSavedManualControlState] = useState(null);
    const executionStartTimeRef = useRef(null);

    // Monitor when sequence naturally finishes (backend returns to MANUAL mode)
    React.useEffect(() => {
        if (!isExecuting) return; // Don't check if not executing
        
        // Check if sequence has finished (at least 1 second after start)
        const now = Date.now();
        const elapsedTime = now - (executionStartTimeRef.current || now);
        
        // Only check after minimum 1 second to avoid false positives
        if (elapsedTime >= 1000 && sensorData && sensorData.mode === 'MANUAL' && !sensorData.is_running) {
            // Sequence has finished naturally
            setIsExecuting(false);
            executionStartTimeRef.current = null;
            
            // Restore Manual Control state (only if not already restored)
            if (savedManualControlState) {
                api.controlGripper(savedManualControlState).catch(e => {
                    console.error('Failed to restore state:', e);
                });
                setSavedManualControlState(null);
            }
        }
    }, [sensorData, isExecuting, savedManualControlState]);

    // Sync with database
    const handleSync = async () => {
        setIsSyncing(true);
        try {
            await syncPatterns();
            Alert.alert('Success', t('syncSuccess') || 'Sync completed successfully');
        } catch (e) {
            console.error('Sync error:', e);
            Alert.alert('Error', t('syncFailed') || 'Sync failed');
        } finally {
            setIsSyncing(false);
        }
    };

    // Open pattern for editing or create new
    const openPattern = (pattern) => {
        if (pattern) {
            // Edit existing pattern
            setSelectedPattern(pattern);
            setPatternName(pattern.name || '');
            setDescription(pattern.description || '');
            setSteps(pattern.steps || []);
            setIsGripMode(true); // Reset to grip mode when opening pattern
        } else {
            // Create new pattern
            setSelectedPattern({ id: null });
            setPatternName('');
            setDescription('');
            setSteps([]);
            setIsGripMode(true); // Reset to grip mode
        }
    };

    // Handle grip/release toggle button
    const handleGripReleaseToggle = () => {
        if (isGripMode) {
            // Current mode is Grip, so add grip action and switch to Release mode
            addAction('grip', { angle: 0 });
            setIsGripMode(false);
        } else {
            // Current mode is Release, so add release action and switch to Grip mode
            addAction('release', { angle: 180 });
            setIsGripMode(true);
        }
    };

    // Add action handlers
    const addAction = (actionType, params) => {
        const newStep = {
            action_type: actionType,
            params: params
        };
        setSteps([...steps, newStep]);
    };

    const addPosition = async () => {
        if (!sensorData) {
            Alert.alert('Error', 'Cannot get current robot position');
            return;
        }
        
        const newStep = {
            action_type: 'move_joints',
            params: {
                j1: sensorData.j1 || 0,
                j2: sensorData.j2 || 0,
                j3: sensorData.j3 || 0,
                j4: sensorData.j4 || 0,
                j5: sensorData.j5 || 0,
                j6: sensorData.j6 || 0,
            }
        };
        setSteps([...steps, newStep]);
    };

    const removeStep = (index) => {
        setSteps(steps.filter((_, i) => i !== index));
    };

    const moveStep = (index, direction) => {
        const newSteps = [...steps];
        if (direction === 'up' && index > 0) {
            [newSteps[index - 1], newSteps[index]] = [newSteps[index], newSteps[index - 1]];
        } else if (direction === 'down' && index < steps.length - 1) {
            [newSteps[index], newSteps[index + 1]] = [newSteps[index + 1], newSteps[index]];
        }
        setSteps(newSteps);
    };

    const handleSave = async () => {
        // Validation: Check if pattern name is not empty
        if (!patternName.trim()) {
            Alert.alert('Error', t('pleaseEnterName') || 'Please enter pattern name');
            return;
        }

        // Validation: Check if there are steps
        if (steps.length === 0) {
            Alert.alert('Error', 'Please add at least one step before saving');
            return;
        }

        // Format steps with step_order for backend compatibility
        const formattedSteps = steps.map((step, index) => ({
            step_order: index,
            action_type: step.action_type,
            params: step.params || {},
        }));

        const pattern = {
            id: selectedPattern?.id || null,
            name: patternName.trim(),
            description: description.trim(),
            steps: formattedSteps
        };

        const success = await savePattern(pattern);
        if (success) {
            Alert.alert('Success', t('patternSaved') || 'Pattern saved successfully');
            // Reset to grip mode and go back to list view
            setIsGripMode(true);
            setPatternName('');
            setDescription('');
            setSteps([]);
            setSelectedPattern(null);
            // Auto sync after save
            setTimeout(() => handleSync(), 500);
        } else {
            Alert.alert('Error', t('saveFailed') || 'Failed to save pattern');
        }
    };

    const handleExecute = async () => {
        if (isExecuting) {
            // Stop execution - STOP SEQUENCE FIRST, then restore state
            setIsExecuting(false);
            executionStartTimeRef.current = null;
            
            // 1. Stop the sequence FIRST (must be first to release the lock)
            try {
                await api.stopSequence();
            } catch (e) {
                console.error('Stop sequence failed:', e);
            }
            
            // 2. Wait a moment for the backend to release the lock
            await new Promise(resolve => setTimeout(resolve, 300));
            
            // 3. Then restore Manual Control state (after lock is released)
            if (savedManualControlState) {
                try {
                    await api.controlGripper(savedManualControlState);
                } catch (e) {
                    console.error('Failed to restore state:', e);
                }
                setSavedManualControlState(null);
            }
        } else {
            // Start execution
            if (steps.length === 0) {
                Alert.alert('Error', t('noSteps') || 'No steps to execute');
                return;
            }

            try {
                // Save current Manual Control state before starting
                if (sensorData) {
                    const currentState = {
                        angle: sensorData.gripper_angle || 180,
                        max_force: sensorData.max_force_setting || 0,
                        switch_on: sensorData.is_gripping || false,
                    };
                    setSavedManualControlState(currentState);
                }

                // Track when execution starts
                executionStartTimeRef.current = Date.now();
                setIsExecuting(true);
                
                // Format steps with step_order for backend
                const formattedSteps = steps.map((step, index) => ({
                    step_order: index,
                    action_type: step.action_type,
                    params: step.params || {},
                }));
                
                const result = await api.executeSequence({
                    steps: formattedSteps,
                    maxForce: 5.0,  // Default max force
                    gripperAngle: 90,  // Default gripper angle
                    isOn: true,
                    patternName: patternName || 'Untitled',
                });
                
                if (!result) {
                    Alert.alert('Error', t('executionFailed') || 'Execution failed');
                    setIsExecuting(false);
                    executionStartTimeRef.current = null;
                    // Restore state on error
                    if (savedManualControlState) {
                        const restored = await api.controlGripper(savedManualControlState);
                        if (!restored) {
                            console.warn('Could not restore state immediately, will try later');
                        } else {
                            setSavedManualControlState(null);
                        }
                    }
                }
                // If successful, keep isExecuting(true) - user will click STOP to finish or auto-detection will detect completion
            } catch (e) {
                console.error('Execution error:', e);
                Alert.alert('Error', e.message || 'Failed to execute sequence');
                setIsExecuting(false);
                executionStartTimeRef.current = null;
                // Restore state on error
                if (savedManualControlState) {
                    try {
                        await api.controlGripper(savedManualControlState);
                        setSavedManualControlState(null);
                    } catch (err) {
                        console.warn('Could not restore state on error:', err);
                    }
                }
            }
        }
    };

    // --- Main List View ---
    if (!selectedPattern && selectedPattern !== 0) {
        return (
            <View style={styles.container}>
                <Header 
                    title={t('teachingMode')} 
                    rightIcon={
                        <TouchableOpacity onPress={handleSync} disabled={isSyncing}>
                            <RefreshCw 
                                color={isSyncing ? '#BDBDBD' : 'white'} 
                                size={24} 
                                style={isSyncing ? { opacity: 0.5 } : {}}
                            />
                        </TouchableOpacity>
                    } 
                />

                <ScrollView contentContainerStyle={styles.listContent}>
                    <Text style={styles.sectionHeader}>{t('savedPatterns')} ({patterns.length})</Text>

                    {patterns.map((p) => (
                        <TouchableOpacity key={p.id} style={styles.patternCard} onPress={() => openPattern(p)}>
                            <View style={styles.patternIcon}>
                                <Text style={styles.patternIdx}>{p.id}</Text>
                            </View>
                            <View style={{ flex: 1, paddingHorizontal: 12 }}>
                                <Text style={styles.cardTitle}>{p.name}</Text>
                                <Text style={styles.cardSub}>Modified: Just now • {p.steps?.length || 0} {t('steps')}</Text>
                            </View>
                            <TouchableOpacity onPress={() => deletePattern(p.id)}>
                                <Trash2 color={colors.danger} size={20} />
                            </TouchableOpacity>
                        </TouchableOpacity>
                    ))}

                    <TouchableOpacity style={styles.createBtn} onPress={() => openPattern(null)}>
                        <Plus color="white" size={24} style={{ marginRight: 8 }} />
                        <Text style={styles.createBtnText}>{t('createNewPattern')}</Text>
                    </TouchableOpacity>
                </ScrollView>
            </View>
        );
    }

    // --- Editor View ---
    return (
        <View style={styles.container}>
            <Header 
                title={selectedPattern.id ? t('editPattern') : t('newPattern')} 
                leftIcon={
                    <TouchableOpacity onPress={() => setSelectedPattern(null)}>
                        <ArrowLeft color="white" size={24} />
                    </TouchableOpacity>
                }
            />

            <ScrollView contentContainerStyle={styles.editorContent}>

                {/* 1. Name Card */}
                <View style={styles.card}>
                    <Text style={styles.label}>{t('patternName')}</Text>
                    <TextInput
                        style={styles.nameInput}
                        value={patternName}
                        onChangeText={setPatternName}
                        placeholder={t('enterName')}
                    />
                    <Text style={[styles.label, { marginTop: 16 }]}>{t('description')} (Optional)</Text>
                    <TextInput
                        style={styles.descInput}
                        value={description}
                        onChangeText={setDescription}
                        placeholder={t('addDesc')}
                        multiline
                    />
                </View>

                {/* 2. Action Controller */}
                <Text style={styles.sectionTitle}>{t('actionController')}</Text>
                <View style={styles.controlCard}>
                    <View style={styles.controlRow}>
                        <TouchableOpacity 
                            style={[
                                styles.bigBtn, 
                                { backgroundColor: isGripMode ? '#FF9800' : '#1976D2' }
                            ]} 
                            onPress={handleGripReleaseToggle}
                        >
                            <Hand color="white" size={24} style={{ marginBottom: 4 }} />
                            <Text style={styles.bigBtnText}>
                                {isGripMode ? t('addGrip') : t('addRelease')}
                            </Text>
                        </TouchableOpacity>

                        <TouchableOpacity style={[styles.bigBtn, { backgroundColor: '#43A047' }]} onPress={addPosition}>
                            <MapPin color="white" size={24} style={{ marginBottom: 4 }} />
                            <Text style={styles.bigBtnText}>{t('addPosition')}</Text>
                        </TouchableOpacity>
                    </View>

                    <View style={styles.waitRow}>
                        <Clock color="#757575" size={20} />
                        <Text style={{ color: '#757575', marginLeft: 8 }}>{t('waitDuration')} (sec)</Text>
                        <TextInput
                            style={{
                                fontWeight: 'bold',
                                fontSize: 16,
                                marginHorizontal: 16,
                                borderBottomWidth: 1,
                                borderColor: '#BDBDBD',
                                minWidth: 40,
                                textAlign: 'center',
                                color: '#212121'
                            }}
                            value={waitDuration}
                            onChangeText={setWaitDuration}
                            keyboardType="numeric"
                        />

                        <TouchableOpacity style={styles.waitBtn} onPress={() => addAction('wait', { duration: parseFloat(waitDuration) || 1.0 })}>
                            <Plus color="white" size={16} style={{ marginRight: 4 }} />
                            <Text style={{ color: 'white', fontWeight: 'bold' }}>{t('addWait')}</Text>
                        </TouchableOpacity>
                    </View>
                </View>

                {/* 3. Recorded Sequence */}
                <Text style={styles.sectionTitle}>{t('recordedSequence')} ({steps.length} {t('stepsCount')})</Text>
                <View style={styles.stepsCard}>
                    <View style={styles.stepsHeader}>
                        <Text style={styles.cardTitle}>{t('steps')}</Text>
                        <TouchableOpacity onPress={() => setSteps([])}>
                            <Text style={{ color: colors.danger, fontWeight: 'bold' }}>{t('clearAll')}</Text>
                        </TouchableOpacity>
                    </View>

                    {steps.map((step, index) => (
                        <View key={index} style={styles.stepRow}>
                            <View style={[styles.stepIdx, { backgroundColor: step.action_type === 'move_joints' ? '#43A047' : step.action_type === 'grip' ? '#FF9800' : '#1976D2' }]}>
                                <Text style={{ color: 'white', fontWeight: 'bold' }}>{index + 1}</Text>
                            </View>

                            <View style={{ flex: 1, paddingHorizontal: 12 }}>
                                <Text style={styles.stepType}>
                                    {step.action_type === 'move_joints' ? 'Position' :
                                        step.action_type === 'wait' ? 'Wait' :
                                            step.action_type === 'grip' ? 'Grip (Close)' : 'Release (Open)'}
                                </Text>
                                <Text style={styles.stepDetail}>
                                    {step.action_type === 'move_joints' ? `(J1:${step.params.j1?.toFixed(0)}° J2:${step.params.j2?.toFixed(0)}°...)` :
                                        step.action_type === 'wait' ? `${step.params.duration} sec` :
                                            step.action_type.toUpperCase()}
                                </Text>
                            </View>

                            <View style={styles.stepActions}>
                                <TouchableOpacity onPress={() => moveStep(index, 'up')}><ArrowUp size={18} color="#90A4AE" /></TouchableOpacity>
                                <TouchableOpacity onPress={() => moveStep(index, 'down')}><ArrowDown size={18} color="#90A4AE" /></TouchableOpacity>
                                <TouchableOpacity onPress={() => removeStep(index)}><Trash2 size={18} color={colors.danger} /></TouchableOpacity>
                            </View>
                        </View>
                    ))}
                </View>

                {/* 4. Testing Area */}
                <View style={styles.card}>
                    <Text style={styles.cardTitle}>{t('testingArea')}</Text>
                    {isExecuting && (
                        <View style={styles.warningBanner}>
                            <Text style={styles.warningText}>⚠️ {t('manualControlDisabled') || 'Manual Control Disabled During Execution'}</Text>
                        </View>
                    )}
                    <TouchableOpacity
                        style={[
                            styles.playBtn,
                            isExecuting ? { backgroundColor: '#D32F2F' } : { backgroundColor: colors.success }
                        ]}
                        onPress={handleExecute}
                    >
                        {isExecuting ? (
                            <>
                                <Square color="white" fill="white" size={20} style={{ marginRight: 8 }} />
                                <Text style={{ color: 'white', fontWeight: 'bold', fontSize: 16 }}>{t('stopSequence')}</Text>
                            </>
                        ) : (
                            <>
                                <Play color="white" fill="white" size={20} style={{ marginRight: 8 }} />
                                <Text style={{ color: 'white', fontWeight: 'bold', fontSize: 16 }}>{t('playSequence')}</Text>
                            </>
                        )}
                    </TouchableOpacity>
                </View>

                {/* 5. Save Button */}
                <TouchableOpacity 
                    style={[
                        styles.saveMainBtn,
                        (steps.length === 0 || !patternName.trim()) && { opacity: 0.5 }
                    ]} 
                    onPress={handleSave}
                    disabled={steps.length === 0 || !patternName.trim()}
                >
                    <Save color="white" size={20} style={{ marginRight: 8 }} />
                    <Text style={{ color: 'white', fontWeight: 'bold', fontSize: 18 }}>{t('savePattern')}</Text>
                </TouchableOpacity>

                <View style={{ height: 40 }} />
            </ScrollView>
        </View>
    );
};



const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: '#F5F5F5' },

    // List Syles
    listContent: { padding: 16 },
    sectionHeader: { fontSize: 16, fontWeight: 'bold', color: '#757575', marginBottom: 16 },
    patternCard: { backgroundColor: 'white', padding: 16, borderRadius: 16, flexDirection: 'row', alignItems: 'center', marginBottom: 12, elevation: 2 },
    patternIcon: { width: 40, height: 40, borderRadius: 20, backgroundColor: colors.primary, justifyContent: 'center', alignItems: 'center' },
    patternIdx: { color: 'white', fontWeight: 'bold', fontSize: 16 },
    cardTitle: { fontSize: 18, fontWeight: 'bold', color: '#212121' },
    cardSub: { fontSize: 12, color: '#9E9E9E' },
    createBtn: { backgroundColor: colors.primary, padding: 16, borderRadius: 12, flexDirection: 'row', justifyContent: 'center', alignItems: 'center', marginTop: 12 },
    createBtnText: { color: 'white', fontWeight: 'bold', fontSize: 16 },

    // Editor Styles
    editorContent: { padding: 16 },
    card: { backgroundColor: 'white', borderRadius: 16, padding: 16, marginBottom: 20, elevation: 1 },
    label: { color: '#757575', fontSize: 12, marginBottom: 4 },
    nameInput: { fontSize: 24, fontWeight: 'bold', color: '#212121', borderBottomWidth: 1, borderColor: '#E0E0E0', paddingBottom: 8 },
    descInput: { fontSize: 14, color: '#212121', height: 40 },

    sectionTitle: { fontSize: 16, fontWeight: 'bold', color: '#757575', marginBottom: 12 },
    controlCard: { backgroundColor: 'white', borderRadius: 16, padding: 16, marginBottom: 20 },
    controlRow: { flexDirection: 'row', gap: 12, marginBottom: 20 },
    bigBtn: { flex: 1, padding: 16, borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
    bigBtnText: { color: 'white', fontWeight: 'bold', fontSize: 12, marginTop: 4 },

    waitRow: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#F5F5F5', padding: 12, borderRadius: 12 },
    waitBtn: { backgroundColor: colors.primary, flexDirection: 'row', paddingVertical: 8, paddingHorizontal: 16, borderRadius: 20, marginLeft: 'auto', alignItems: 'center' },

    stepsCard: { backgroundColor: 'white', borderRadius: 16, padding: 16, marginBottom: 20 },
    stepsHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 16 },
    stepRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 12, borderBottomWidth: 1, borderColor: '#EEEEEE' },
    stepIdx: { width: 32, height: 32, borderRadius: 16, justifyContent: 'center', alignItems: 'center' },
    stepType: { fontWeight: 'bold', color: '#212121', fontSize: 14 },
    stepDetail: { fontSize: 12, color: '#757575' },
    stepActions: { flexDirection: 'row', gap: 12 },

    playBtn: { backgroundColor: colors.success, flexDirection: 'row', padding: 16, borderRadius: 12, justifyContent: 'center', alignItems: 'center', marginTop: 12 },
    saveMainBtn: { backgroundColor: colors.primary, flexDirection: 'row', padding: 16, borderRadius: 12, justifyContent: 'center', alignItems: 'center', marginBottom: 24 },
    warningBanner: { backgroundColor: '#FFF3E0', borderLeftWidth: 4, borderLeftColor: '#FF9800', padding: 12, borderRadius: 8, marginBottom: 12 },
    warningText: { color: '#E65100', fontWeight: '600', fontSize: 14 },
});
