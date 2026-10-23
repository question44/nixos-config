import React, { useEffect, useMemo, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import {
  Alert, Box, Button, ButtonBase, Card, CardActionArea, Chip, Container,
  CssBaseline, Dialog, DialogActions, DialogContent, DialogContentText,
  DialogTitle, Stack, SvgIcon, ThemeProvider, Typography, createTheme, useMediaQuery,
} from '@mui/material';

const paths = {
  display: 'M3 4h18v12H3z M8 20h8 M12 16v4',
  light: 'M12 2v2 M12 20v2 M2 12h2 M20 12h2 M5 5l1.5 1.5 M17.5 17.5L19 19 M5 19l1.5-1.5 M17.5 6.5L19 5 M16 12a4 4 0 1 0-8 0 4 4 0 0 0 8 0',
  sleep: 'M20.5 13A9 9 0 0 1 11 3.5 9 9 0 1 0 20.5 13Z',
  power: 'M12 3v9 M5.6 5.6a9 9 0 1 0 12.8 0',
  media: 'M5 3h14v18H5z M10 8l6 4-6 4z',
  cloud: 'M7 18h11a4 4 0 0 0 0-8 6 6 0 0 0-11-2 5 5 0 0 0 0 10Z',
  sync: 'M3 10a9 9 0 0 1 15-5l3 3 M21 3v5h-5 M21 14a9 9 0 0 1-15 5l-3-3 M3 21v-5h5',
  torrent: 'M12 3v12 M7 10l5 5 5-5 M4 16v5h16v-5',
  code: 'm8 6-6 6 6 6 M16 6l6 6-6 6 M14 3l-4 18',
  system: 'M4 4h16v12H4z M8 20h8 M12 16v4 M8 8l3 2-3 2 M13 12h3',
  arrow: 'M7 17 17 7 M7 7h10v10',
};
function Icon({ name, ...props }) {
  return <SvgIcon {...props}><path d={paths[name]} fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" /></SvgIcon>;
}
const actions = [
  { id: 'display-on', label: 'Display on', icon: 'display' },
  { id: 'display-off', label: 'Display off', icon: 'display', off: true },
  { id: 'ambilight-on', label: 'Ambilight on', icon: 'light' },
  { id: 'ambilight-off', label: 'Ambilight off', icon: 'light', off: true },
  { id: 'sleep', label: 'Sleep', icon: 'sleep', confirm: 'Put erebor to sleep? Remote services will disconnect until it wakes.' },
  { id: 'power-off', label: 'Power off', icon: 'power', danger: true, confirm: 'Power off erebor? Save your work first. Remote services will stop.' },
];
const domain = location.hostname.endsWith('.jzon.pl');
const serviceUrl = (name, port) => domain ? `https://${name}.${location.hostname}` : `http://${location.hostname}:${port}`;
const services = [
  { id: 'jellyfin', label: 'Media', description: 'Jellyfin media library', icon: 'media', url: serviceUrl('media', 8096) },
  { id: 'nextcloud', label: 'Cloud', description: 'Nextcloud files and calendar', icon: 'cloud', url: serviceUrl('cloud', 8095) },
  { id: 'syncthing', label: 'Sync', description: 'Syncthing devices and folders', icon: 'sync', url: serviceUrl('sync', 8384) },
  { id: 'qbittorrent', label: 'Torrent', description: 'qBittorrent downloads', icon: 'torrent', url: serviceUrl('torrent', 8082) },
  { id: 't3code', label: 'Code', description: 'T3 Code collaborative workspace', icon: 'code', url: serviceUrl('code', 8080) },
  { id: 'hyperhdr', label: 'HyperHDR', description: 'Ambilight capture and LED settings', icon: 'light', url: serviceUrl('hyperhdr', 8090) },
  { id: 'sunshine', label: 'Sunshine', description: 'Game streaming and Moonlight pairing', icon: 'light', url: domain ? `https://sunshine.${location.hostname}` : `https://${location.hostname}:47990` },
  { id: 'cockpit', label: 'System', description: 'Cockpit server administration', icon: 'system', url: 'https://sys.erebor.jzon.pl' },
];

function Dashboard() {
  const dark = useMediaQuery('(prefers-color-scheme: dark)');
  const theme = useMemo(() => createTheme({
    palette: {
      mode: dark ? 'dark' : 'light',
      primary: { main: dark ? '#d0bcff' : '#6750a4' },
      background: { default: dark ? '#141218' : '#fdf8ff', paper: dark ? '#211f26' : '#f3edf7' },
    },
    shape: { borderRadius: 20 },
    typography: { fontFamily: 'system-ui, -apple-system, "Segoe UI", sans-serif', button: { textTransform: 'none', fontWeight: 600 } },
    components: { MuiCard: { defaultProps: { elevation: 0 } }, MuiButton: { styleOverrides: { root: { borderRadius: 24 } } } },
  }), [dark]);
  const [online, setOnline] = useState(navigator.onLine);
  const [busy, setBusy] = useState(false);
  const lock = useRef(false);
  const [status, setStatus] = useState(null);
  const [confirmation, setConfirmation] = useState(null);
  const [installPrompt, setInstallPrompt] = useState(null);
  useEffect(() => {
    const connection = () => setOnline(navigator.onLine);
    const install = event => { event.preventDefault(); setInstallPrompt(event); };
    const installed = () => setInstallPrompt(null);
    window.addEventListener('online', connection);
    window.addEventListener('offline', connection);
    window.addEventListener('beforeinstallprompt', install);
    window.addEventListener('appinstalled', installed);
    return () => {
      window.removeEventListener('online', connection);
      window.removeEventListener('offline', connection);
      window.removeEventListener('beforeinstallprompt', install);
      window.removeEventListener('appinstalled', installed);
    };
  }, []);
  useEffect(() => {
    document.querySelector('meta[name="theme-color"]').content = dark ? '#141218' : '#fdf8ff';
  }, [dark]);
  async function execute(action) {
    setConfirmation(null);
    if (lock.current || !navigator.onLine) return;
    lock.current = true;
    setBusy(true);
    setStatus({ severity: 'info', text: 'Sending command…' });
    try {
      const response = await fetch('/api/control', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-Erebor-Control': '1' },
        body: JSON.stringify({ action: action.id }),
        signal: AbortSignal.timeout(20000),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.error || 'Command failed');
      setStatus({ severity: 'success', text: `${action.label}: command sent.` });
    } catch (error) {
      setStatus({ severity: 'error', text: action.confirm
        ? 'Connection lost or command failed. Check whether erebor is asleep or powered off.'
        : error.message });
    } finally {
      lock.current = false;
      setBusy(false);
    }
  }
  return <ThemeProvider theme={theme}>
    <CssBaseline />
    <Container maxWidth="md" component="main" sx={{ py: { xs: 3, sm: 6 } }}>
      <Stack direction="row" sx={{ alignItems: "center", justifyContent: "space-between", gap: 2, mb: 1 }}>
        <Typography variant="h3" component="h1" sx={{ fontWeight: 650, letterSpacing: '-.04em' }}>erebor</Typography>
        <Chip size="small" label={online ? 'Local & tailnet' : 'Offline'} variant="outlined" />
      </Stack>
      <Typography sx={{ color: "text.secondary", mb: 4 }}>Services available on the tailnet and local network.</Typography>
      {installPrompt && <Button variant="outlined" sx={{ mb: 3 }} onClick={async () => {
        const prompt = installPrompt; setInstallPrompt(null); await prompt.prompt();
      }}>Install erebor</Button>}
      {!online && <Alert severity="warning" sx={{ mb: 3 }}>Offline — reconnect to use services and controls.</Alert>}
      <Box component="section" aria-labelledby="quick-actions-title">
        <Typography variant="h6" component="h2" id="quick-actions-title" sx={{ mb: 2 }}>Quick actions</Typography>
        <Box sx={{ display: 'grid', gridTemplateColumns: { xs: 'repeat(3, minmax(0, 1fr))', sm: 'repeat(6, minmax(0, 1fr))' }, gap: 1.25 }}>
          {actions.map(action => <ButtonBase key={action.id} data-action={action.id} disabled={busy || !online}
            onClick={() => action.confirm ? setConfirmation(action) : execute(action)}
            sx={{ flexDirection: 'column', gap: 1.25, minHeight: 104, px: .5, py: 2, borderRadius: "24px",
              bgcolor: 'background.paper', color: action.danger ? 'error.main' : action.off ? 'text.secondary' : 'primary.main',
              transition: 'background-color .15s', '&:hover': { bgcolor: 'action.hover' },
              '&.Mui-focusVisible': { outline: '3px solid', outlineOffset: 3, outlineColor: 'primary.main' },
              '&.Mui-disabled': { opacity: .4 } }}>
            <Icon name={action.icon} sx={{ fontSize: 26 }} />
            <Typography component="span" variant="body2" sx={{ fontWeight: 600, fontSize: '.8rem' }}>{action.label}</Typography>
          </ButtonBase>)}
        </Box>
        {status && <Alert severity={status.severity} sx={{ mt: 2 }} role="status" aria-live="polite">{status.text}</Alert>}
      </Box>
      <Typography variant="h6" component="h2" sx={{ mt: 4, mb: 2 }}>Services</Typography>
      <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, minmax(0, 1fr))' }, gap: 1.5 }}>
        {services.map(service => <Card key={service.id}>
          <CardActionArea id={service.id} href={service.url} sx={{ height: '100%', p: 2.5, display: 'flex', gap: 2, justifyContent: 'flex-start' }}>
            <Box sx={{ display: 'grid', placeItems: 'center', borderRadius: "16px", p: 1.25, bgcolor: dark ? '#363043' : '#e8def8', color: 'primary.main' }}><Icon name={service.icon} /></Box>
            <Box sx={{ flex: 1 }}>
              <Typography component="h3" variant="subtitle1" sx={{ fontWeight: 650 }}>{service.label}</Typography>
              <Typography variant="body2" sx={{ color: "text.secondary" }}>{service.description}</Typography>
            </Box>
            <Icon name="arrow" sx={{ fontSize: 18, color: 'text.secondary' }} />
          </CardActionArea>
        </Card>)}
      </Box>
      <Typography component="footer" variant="caption" sx={{ color: "text.secondary", display: 'block', mt: 4 }}>
        Install from your browser menu. On iPhone or iPad, use Share → Add to Home Screen.
      </Typography>
      <Dialog open={!!confirmation} onClose={() => setConfirmation(null)} aria-labelledby="confirm-title">
        <DialogTitle id="confirm-title">{confirmation?.label} erebor?</DialogTitle>
        <DialogContent><DialogContentText>{confirmation?.confirm}</DialogContentText></DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setConfirmation(null)}>Cancel</Button>
          <Button variant="contained" color={confirmation?.danger ? 'error' : 'primary'} disabled={!online || busy} onClick={() => execute(confirmation)}>{confirmation?.label}</Button>
        </DialogActions>
      </Dialog>
    </Container>
  </ThemeProvider>;
}

createRoot(document.getElementById('root')).render(<Dashboard />);
if ('serviceWorker' in navigator && isSecureContext) {
  navigator.serviceWorker.register('/sw.js', { updateViaCache: 'none' })
    .catch(error => console.error('Offline support unavailable:', error));
}
