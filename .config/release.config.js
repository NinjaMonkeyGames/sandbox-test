export default {
  branches: [
    'master',
    { name: 'develop', channel: 'beta', prerelease: 'beta' },
    { name: 'release/*', channel: 'rc', prerelease: 'rc' },
  ],

  plugins: [
    // Determines the next version bump (major/minor/patch/none) from
    // commits since the last release.
    ['@semantic-release/commit-analyzer', { preset: 'conventionalcommits' }],
    ['@semantic-release/github', { successComment: false, failComment: false }],
  ],
};