import React, { useEffect, useState } from 'react';
import {
  View, Text, ScrollView, TouchableOpacity, StyleSheet,
  Alert, ActivityIndicator, Linking, TextInput,
} from 'react-native';
import { useRoute, RouteProp, useNavigation } from '@react-navigation/native';
import { supabase } from '../lib/supabase';
import { Job, RootStackParamList } from '../types';

type RouteProps = RouteProp<RootStackParamList, 'JobDetail'>;

const SURVEY_LABELS: Record<string, string> = {
  bs5837: 'BS5837 Tree Survey (Planning)', vta: 'Visual Tree Assessment',
  bc: 'BS5837 Stage 2 (AIA/AMS/TPP)', subs: 'Subsidence / Building Damage',
  mortgage: 'Mortgage / Insurer Report', amendment: 'Amendment', other: 'Other',
};

export default function JobDetailScreen() {
  const { params: { jobId } } = useRoute<RouteProps>();
  const nav = useNavigation();
  const [job,        setJob]        = useState<Job | null>(null);
  const [surveyorId, setSurveyorId] = useState<string | null>(null);
  const [loading,    setLoading]    = useState(true);
  const [notes,      setNotes]      = useState('');
  const [savingNotes, setSavingNotes] = useState(false);

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    const { data: { user } } = await supabase.auth.getUser();

    const [{ data: jobData }, { data: survData }] = await Promise.all([
      supabase.from('jobs').select('*').eq('id', jobId).single(),
      supabase.from('surveyors').select('id').eq('user_id', user?.id || '').single(),
    ]);

    setJob(jobData);
    setSurveyorId(survData?.id || null);
    setNotes(jobData?.surveyor_notes || '');
    setLoading(false);
  }

  async function claimJob() {
    if (!surveyorId) { Alert.alert('Error', 'Surveyor profile not found.'); return; }
    Alert.alert('Claim Job', 'Confirm you want to claim this job?', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Claim', onPress: async () => {
        const { error } = await supabase.rpc('claim_job', { p_job_id: jobId, p_surveyor_id: surveyorId });
        if (error) Alert.alert('Error', error.message);
        else { Alert.alert('Claimed!', 'Job is now assigned to you.'); loadData(); }
      }},
    ]);
  }

  async function handBack() {
    Alert.prompt('Hand Back Job', 'Reason (optional):', async (reason) => {
      const { error } = await supabase.rpc('hand_back_job', { p_job_id: jobId, p_note: reason || null });
      if (error) Alert.alert('Error', error.message);
      else { Alert.alert('Done', 'Job returned to the map.'); nav.goBack(); }
    });
  }

  async function markFieldDataUploaded() {
    Alert.alert('Confirm', 'Mark field data as uploaded? This notifies the office.', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Confirm', onPress: async () => {
        const { error } = await supabase.from('jobs').update({
          field_data_uploaded: true,
          field_data_uploaded_at: new Date().toISOString(),
          dispatch_state: 'yellow',
        }).eq('id', jobId);
        if (error) Alert.alert('Error', error.message);
        else { Alert.alert('Done', 'Field data marked as uploaded.'); loadData(); }
      }},
    ]);
  }

  async function saveNotes() {
    setSavingNotes(true);
    const { error } = await supabase.from('jobs').update({ surveyor_notes: notes }).eq('id', jobId);
    setSavingNotes(false);
    if (error) Alert.alert('Error', error.message);
    else Alert.alert('Saved', 'Notes saved.');
  }

  if (loading) return <View style={s.center}><ActivityIndicator size="large" color="#1a3c2e" /></View>;
  if (!job) return <View style={s.center}><Text>Job not found.</Text></View>;

  const isMine = job.surveyor_id === surveyorId;
  const isAvailable = job.dispatch_state === 'red';

  return (
    <ScrollView style={s.container} contentContainerStyle={{ padding: 16, gap: 12 }}>

      {/* Header */}
      <View style={s.card}>
        <Text style={s.ref}>{job.reference || 'No reference'}</Text>
        <Text style={s.type}>{SURVEY_LABELS[job.survey_type] || job.survey_type}</Text>
        <Text style={s.postcode}>{job.site_postcode || '—'}</Text>
        {job.surveyor_pay_amount
          ? <Text style={s.pay}>Your pay: £{job.surveyor_pay_amount.toFixed(2)}</Text>
          : null}
        {job.sla_deadline
          ? <Text style={s.sla}>SLA: {new Date(job.sla_deadline).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })}</Text>
          : null}
      </View>

      {/* Site Access */}
      {job.site_access_notes ? (
        <View style={s.card}>
          <Text style={s.sectionTitle}>Site Access</Text>
          <Text style={s.body}>{job.site_access_notes}</Text>
          {job.site_location_tag
            ? <Text style={s.tag}>{job.site_location_tag}</Text>
            : null}
        </View>
      ) : null}

      {/* Survey Date */}
      {job.survey_date ? (
        <View style={s.card}>
          <Text style={s.sectionTitle}>Survey Date</Text>
          <Text style={s.body}>
            {new Date(job.survey_date).toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })}
            {' '}{job.survey_date_confirmed ? '✅ Confirmed' : '🟠 Proposed'}
          </Text>
        </View>
      ) : null}

      {/* Documents */}
      {(job.doc_block_plan_url || job.doc_topo_survey_url || job.doc_other_urls) ? (
        <View style={s.card}>
          <Text style={s.sectionTitle}>Documents</Text>
          {job.doc_block_plan_url
            ? <TouchableOpacity style={s.docBtn} onPress={() => Linking.openURL(job.doc_block_plan_url!)}>
                <Text style={s.docBtnText}>📄 Block Plan</Text>
              </TouchableOpacity>
            : null}
          {job.doc_topo_survey_url
            ? <TouchableOpacity style={s.docBtn} onPress={() => Linking.openURL(job.doc_topo_survey_url!)}>
                <Text style={s.docBtnText}>📄 Topo Survey</Text>
              </TouchableOpacity>
            : null}
          {job.doc_other_urls
            ? <Text style={s.body}>{job.doc_other_urls}</Text>
            : null}
        </View>
      ) : null}

      {/* Surveyor notes */}
      {isMine && (
        <View style={s.card}>
          <Text style={s.sectionTitle}>Field Notes</Text>
          <TextInput
            style={s.notesInput}
            multiline
            numberOfLines={4}
            placeholder="Add your site notes here…"
            value={notes}
            onChangeText={setNotes}
          />
          <TouchableOpacity style={s.saveBtn} onPress={saveNotes} disabled={savingNotes}>
            <Text style={s.saveBtnText}>{savingNotes ? 'Saving…' : 'Save Notes'}</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* Actions */}
      <View style={s.actions}>
        {isAvailable && (
          <TouchableOpacity style={s.btnPrimary} onPress={claimJob}>
            <Text style={s.btnPrimaryText}>✅ Claim This Job</Text>
          </TouchableOpacity>
        )}
        {isMine && job.dispatch_state === 'orange' && (
          <>
            <TouchableOpacity style={s.btnPrimary} onPress={markFieldDataUploaded}>
              <Text style={s.btnPrimaryText}>📤 Mark Field Data Uploaded</Text>
            </TouchableOpacity>
            <TouchableOpacity style={s.btnSecondary} onPress={handBack}>
              <Text style={s.btnSecondaryText}>↩ Hand Back Job</Text>
            </TouchableOpacity>
          </>
        )}
        {isMine && job.dispatch_state === 'yellow' && (
          <View style={s.infoBox}>
            <Text style={s.infoText}>🟡 Field data uploaded. Awaiting report finalisation.</Text>
          </View>
        )}
      </View>

    </ScrollView>
  );
}

const GREEN = '#1a3c2e';

const s = StyleSheet.create({
  container:     { flex: 1, backgroundColor: '#f5f5f5' },
  center:        { flex: 1, justifyContent: 'center', alignItems: 'center' },
  card:          { backgroundColor: '#fff', borderRadius: 12, padding: 16, elevation: 2 },
  ref:           { fontSize: 20, fontWeight: '700', color: GREEN, marginBottom: 4 },
  type:          { fontSize: 15, color: '#374151', marginBottom: 2 },
  postcode:      { fontSize: 14, color: '#6b7280' },
  pay:           { fontSize: 16, fontWeight: '700', color: '#16a34a', marginTop: 8 },
  sla:           { fontSize: 13, color: '#6b7280', marginTop: 4 },
  sectionTitle:  { fontSize: 14, fontWeight: '700', color: GREEN, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 0.5 },
  body:          { fontSize: 14, color: '#374151', lineHeight: 20 },
  tag:           { fontSize: 12, color: '#6b7280', marginTop: 6, fontStyle: 'italic' },
  docBtn:        { backgroundColor: '#f0f7f4', borderRadius: 8, padding: 12, marginBottom: 8 },
  docBtnText:    { color: GREEN, fontWeight: '600', fontSize: 14 },
  notesInput:    { borderWidth: 1, borderColor: '#d1d5db', borderRadius: 8, padding: 12, fontSize: 14, minHeight: 100, textAlignVertical: 'top', marginBottom: 8 },
  saveBtn:       { backgroundColor: '#e5f0eb', borderRadius: 8, padding: 10, alignItems: 'center' },
  saveBtnText:   { color: GREEN, fontWeight: '600', fontSize: 14 },
  actions:       { gap: 10, paddingBottom: 32 },
  btnPrimary:    { backgroundColor: GREEN, borderRadius: 12, padding: 16, alignItems: 'center' },
  btnPrimaryText:{ color: '#fff', fontSize: 16, fontWeight: '700' },
  btnSecondary:  { backgroundColor: '#fff', borderRadius: 12, padding: 16, alignItems: 'center', borderWidth: 1, borderColor: '#d1d5db' },
  btnSecondaryText: { color: '#dc2626', fontSize: 15, fontWeight: '600' },
  infoBox:       { backgroundColor: '#fefce8', borderRadius: 12, padding: 16 },
  infoText:      { color: '#854d0e', fontSize: 14, textAlign: 'center' },
});
