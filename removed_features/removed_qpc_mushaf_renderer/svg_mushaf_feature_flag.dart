const bool forceQpcMushaf = bool.fromEnvironment(
  'FORCE_QPC_MUSHAF',
  defaultValue: false,
);

const bool useSvgImageMushaf = !forceQpcMushaf;
