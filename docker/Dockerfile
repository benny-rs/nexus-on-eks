# ---------------------------------------------------------------------------
# Nexus Repository OSS — AWS variant
#
# S3 blobstore is built into Nexus since 3.19 — no plugin required.
# No version pinning needed; we can always track the latest Nexus release.
# ---------------------------------------------------------------------------
FROM sonatype/nexus3:3.68.0

USER nexus

EXPOSE 8081
VOLUME ["/nexus-data"]

ENTRYPOINT ["/opt/sonatype/nexus/bin/nexus"]
CMD ["run"]
