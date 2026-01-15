import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity, TextInput, Alert, Platform } from 'react-native';
import { useRobot } from '../features/RobotContext';
import { api } from '../api/api';
import { colors } from '../theme/colors';
import { Header } from '../components/Header';
import { Play, Trash2, Plus, Save, ArrowLeft, ArrowUp, ArrowDown, MapPin, Hand, Clock, RefreshCw, Square } from 'lucide-react-native';

import { useLanguage } from '../features/LanguageContext';

export const TeachingScreen = () => {
    const { patterns, savePattern, deletePattern, sensorData } = useRobot();
    const { t } = useLanguage();
    const [selectedPattern, setSelectedPattern] = useState(null);

    // ... State ...

    // ... Handlers ...

    // --- Main List View ---
    if (!selectedPattern && selectedPattern !== 0) {
        return (
            <View style={styles.container}>
                <Header title={t('teachingMode')} rightIcon={<RefreshCw color="white" size={24} />} />

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
            <View style={styles.navHeader}>
                <TouchableOpacity onPress={() => setSelectedPattern(null)}>
                    <ArrowLeft color="white" size={24} />
                </TouchableOpacity>
                <Text style={styles.navTitle}>{selectedPattern.id ? t('editPattern') : t('newPattern')}</Text>
                <View style={{ width: 24 }} />
            </View>

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
                        <TouchableOpacity style={[styles.bigBtn, { backgroundColor: '#FF9800' }]} onPress={() => addAction('grip', { angle: 0 })}>
                            <Hand color="white" size={24} style={{ marginBottom: 4 }} />
                            <Text style={styles.bigBtnText}>{t('addGrip')}</Text>
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
                    <TouchableOpacity
                        style={[styles.playBtn, isExecuting && { backgroundColor: colors.danger }]}
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
                <TouchableOpacity style={styles.saveMainBtn} onPress={handleSave}>
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

    // Header
    navHeader: { backgroundColor: colors.primary, padding: 16, paddingTop: 48, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
    navTitle: { color: 'white', fontSize: 20, fontWeight: 'bold' },

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
    saveMainBtn: { backgroundColor: colors.primary, flexDirection: 'row', padding: 16, borderRadius: 12, justifyContent: 'center', alignItems: 'center', marginBottom: 24 }
});
