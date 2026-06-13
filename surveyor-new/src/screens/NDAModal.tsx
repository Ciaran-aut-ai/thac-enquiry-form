import React, { useState } from 'react';
import {
  Modal, View, Text, ScrollView, TouchableOpacity, StyleSheet,
  Alert,
} from 'react-native';

interface NDAModalProps {
  visible: boolean;
  onAccept: () => void;
  onDismiss: () => void;
}

export default function NDAModal({ visible, onAccept, onDismiss }: NDAModalProps) {
  const [accepted, setAccepted] = useState(false);

  const handleAccept = () => {
    if (!accepted) {
      Alert.alert('Required', 'You must accept the terms to proceed');
      return;
    }
    setAccepted(false);
    onAccept();
  };

  return (
    <Modal visible={visible} animationType="slide" onRequestClose={onDismiss}>
      <View style={s.container}>
        <View style={s.header}>
          <Text style={s.title}>Service Agreement & Confidentiality</Text>
          <TouchableOpacity onPress={onDismiss} style={s.closeBtn}>
            <Text style={s.closeText}>✕</Text>
          </TouchableOpacity>
        </View>

        <ScrollView style={s.content} contentContainerStyle={s.contentInner}>
          <Text style={s.sectionTitle}>SERVICE AGREEMENT & CONFIDENTIALITY OBLIGATION</Text>

          <Text style={s.text}>
            By accepting this job, you agree to the following legally binding terms:
          </Text>

          <Text style={s.heading}>1. NON-SOLICITATION</Text>
          <Text style={s.text}>
            You agree NOT to solicit, contact, or enter into independent agreements with the client for any arboricultural services related to this job. Any work performed directly with the client without THAC involvement is a breach of contract.
          </Text>

          <Text style={s.heading}>2. CONFIDENTIALITY</Text>
          <Text style={s.text}>
            All client information (names, addresses, contact details, site conditions, specifications, pricing) is confidential and proprietary to THAC. You must not disclose this information to any third party or use it for your own benefit.
          </Text>

          <Text style={s.heading}>3. BREACH CONSEQUENCES</Text>
          <Text style={s.text}>
            Breach of these terms may result in:
          </Text>
          <Text style={s.bullet}>• Legal action and damages claims</Text>
          <Text style={s.bullet}>• Termination of surveyor agreement</Text>
          <Text style={s.bullet}>• Liability for loss of business/revenue</Text>
          <Text style={s.bullet}>• Recovery of client acquisition costs</Text>

          <Text style={s.heading}>4. BINDING AGREEMENT</Text>
          <Text style={s.text}>
            This is a legally binding agreement under English law. Your acceptance creates a contractual obligation that you understand and agree to these terms.
          </Text>

          <View style={s.divider} />

          <View style={s.checkboxContainer}>
            <TouchableOpacity
              onPress={() => setAccepted(!accepted)}
              style={s.checkbox}
            >
              {accepted && <Text style={s.checkmark}>✓</Text>}
            </TouchableOpacity>
            <Text style={s.checkboxLabel}>
              I have read and understand these terms
            </Text>
          </View>
        </ScrollView>

        <View style={s.footer}>
          <TouchableOpacity
            style={[s.button, s.cancelBtn]}
            onPress={onDismiss}
          >
            <Text style={s.cancelText}>Cancel</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[s.button, s.acceptBtn, !accepted && s.acceptBtnDisabled]}
            onPress={handleAccept}
            disabled={!accepted}
          >
            <Text style={s.acceptText}>I Accept & Claim Job</Text>
          </TouchableOpacity>
        </View>
      </View>
    </Modal>
  );
}

const s = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    marginTop: 40,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
  },
  title: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1a3c2e',
    flex: 1,
  },
  closeBtn: {
    width: 40,
    height: 40,
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeText: {
    fontSize: 24,
    color: '#9ca3af',
  },
  content: {
    flex: 1,
  },
  contentInner: {
    padding: 16,
    paddingBottom: 24,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#1a3c2e',
    marginBottom: 12,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  text: {
    fontSize: 13,
    color: '#374151',
    lineHeight: 20,
    marginBottom: 12,
  },
  heading: {
    fontSize: 13,
    fontWeight: '700',
    color: '#1a3c2e',
    marginTop: 16,
    marginBottom: 8,
  },
  bullet: {
    fontSize: 13,
    color: '#374151',
    lineHeight: 20,
    marginLeft: 16,
    marginBottom: 6,
  },
  divider: {
    height: 1,
    backgroundColor: '#e5e7eb',
    marginVertical: 16,
  },
  checkboxContainer: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
  },
  checkbox: {
    width: 24,
    height: 24,
    borderWidth: 2,
    borderColor: '#1a3c2e',
    borderRadius: 4,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 2,
  },
  checkmark: {
    fontSize: 16,
    color: '#1a3c2e',
    fontWeight: '700',
  },
  checkboxLabel: {
    fontSize: 13,
    color: '#374151',
    fontWeight: '500',
    lineHeight: 20,
    flex: 1,
  },
  footer: {
    flexDirection: 'row',
    gap: 12,
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: '#e5e7eb',
    backgroundColor: '#f9fafb',
  },
  button: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  cancelBtn: {
    backgroundColor: '#f3f4f6',
  },
  cancelText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#374151',
  },
  acceptBtn: {
    backgroundColor: '#1a3c2e',
  },
  acceptBtnDisabled: {
    backgroundColor: '#d1d5db',
  },
  acceptText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#fff',
  },
});
