import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { StatusBar } from 'expo-status-bar';
import { RobotProvider } from './src/features/RobotContext';
import { AppNavigator } from './src/navigation/AppNavigator';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { LanguageProvider } from './src/features/LanguageContext';

export default function App() {
  return (
    <SafeAreaProvider>
      <LanguageProvider>
        <RobotProvider>
          <NavigationContainer>
            <AppNavigator />
            <StatusBar style="light" />
          </NavigationContainer>
        </RobotProvider>
      </LanguageProvider>
    </SafeAreaProvider>
  );
}
