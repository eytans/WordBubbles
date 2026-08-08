{{flutter_js}}
{{flutter_build_config}}

// Keep CanvasKit inside the deployed artifact so the web build can start after
// its first load without reaching out to the default gstatic runtime host.
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  config: {
    useLocalCanvasKit: true,
  },
});
