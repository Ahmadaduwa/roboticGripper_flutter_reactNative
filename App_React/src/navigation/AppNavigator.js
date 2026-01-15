import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createStackNavigator } from '@react-navigation/stack';
import { DashboardScreen } from '../screens/DashboardScreen';
import { ControlScreen } from '../screens/ControlScreen';
import { TeachingScreen } from '../screens/TeachingScreen';
import { AutoRunScreen } from '../screens/AutoRunScreen';
import { SettingsScreen } from '../screens/SettingsScreen';
import { SplashScreen } from '../screens/SplashScreen';
import { colors } from '../theme/colors';
import { Activity, Move, BookOpen, PlayCircle, Settings } from 'lucide-react-native';
import { useLanguage } from '../features/LanguageContext';

const Tab = createBottomTabNavigator();
const Stack = createStackNavigator();

const MainTabs = () => {
    const { t } = useLanguage();

    return (
        <Tab.Navigator
            screenOptions={{
                // ... styles
                headerShown: false,
                tabBarStyle: {
                    backgroundColor: colors.card,
                    borderTopWidth: 0,
                    elevation: 10,
                    shadowColor: '#000',
                    shadowOffset: { width: 0, height: -2 },
                    shadowOpacity: 0.1,
                    shadowRadius: 4,
                    height: 70,
                    paddingBottom: 10,
                    paddingTop: 10
                },
                tabBarActiveTintColor: colors.primary,
                tabBarInactiveTintColor: colors.textSecondary,
                tabBarLabelStyle: { fontSize: 10, fontFamily: 'System', fontWeight: '600' }
            }}
        >
            <Tab.Screen
                name="Dashboard"
                component={DashboardScreen}
                options={{
                    title: t('dashboard'),
                    tabBarLabel: t('dashboard'),
                    tabBarIcon: ({ color }) => <Activity color={color} size={24} />
                }}
            />
            <Tab.Screen
                name="Control"
                component={ControlScreen}
                options={{
                    title: t('control'),
                    tabBarLabel: t('control'),
                    tabBarIcon: ({ color }) => <Move color={color} size={24} />
                }}
            />
            <Tab.Screen
                name="Teaching"
                component={TeachingScreen}
                options={{
                    title: t('teaching'),
                    tabBarLabel: t('teaching'),
                    tabBarIcon: ({ color }) => <BookOpen color={color} size={24} />
                }}
            />
            <Tab.Screen
                name="Auto Run"
                component={AutoRunScreen}
                options={{
                    title: t('autoRun'),
                    tabBarLabel: t('autoRun'),
                    tabBarIcon: ({ color }) => <PlayCircle color={color} size={24} />
                }}
            />
            <Tab.Screen
                name="Settings"
                component={SettingsScreen}
                options={{
                    title: t('settings'),
                    tabBarLabel: t('settings'),
                    tabBarIcon: ({ color }) => <Settings color={color} size={24} />
                }}
            />
        </Tab.Navigator>
    );
};

export const AppNavigator = () => (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
        <Stack.Screen name="Splash" component={SplashScreen} />
        <Stack.Screen name="Main" component={MainTabs} />
    </Stack.Navigator>
);
