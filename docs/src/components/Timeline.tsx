import { useState } from 'react';

interface Milestone {
  hash: string;
  shortHash: string;
  message: string;
  date: string;
  type: 'feature' | 'improvement' | 'milestone';
  description?: string;
}

const milestones: Milestone[] = [
  {
    hash: '7058b0fde6b864b562c6fb3376533b17968db1c8',
    shortHash: '7058b0f',
    message: 'Type Checker',
    date: '2025-12-29',
    type: 'feature',
    description: 'Introduced static type checking to catch type errors at compile time'
  },
  {
    hash: 'd3e98d2d2491f6f3d5ff2fb0d16c190441036fed',
    shortHash: 'd3e98d2',
    message: 'If-Else Statements',
    date: '2025-12-22',
    type: 'feature',
    description: 'Added conditional branching with if-else statements'
  },
  {
    hash: 'a83aa41182889fa9d6e32bcb5c8a519e00c60bb4',
    shortHash: 'a83aa41',
    message: 'Comparison Operators',
    date: '2025-12-21',
    type: 'feature',
    description: 'Implemented comparison operators (==, !=, <, >, <=, >=)'
  },
  {
    hash: 'b9b6ba263fa7518f460617612ea7b48f048e7213',
    shortHash: 'b9b6ba2',
    message: 'Print Function (Standard Library)',
    date: '2025-12-21',
    type: 'feature',
    description: 'Added the print() function as the first standard library function'
  },
  {
    hash: 'c55cbafab19592f7d54113872d9a6e852094d592',
    shortHash: 'c55cbaf',
    message: 'Functions',
    date: '2025-12-18',
    type: 'feature',
    description: 'Full support for function definitions and calls with parameters'
  },
  {
    hash: '13fedf7a0b488d5608c8123fda284ab3649499b8',
    shortHash: '13fedf7',
    message: 'Constants',
    date: '2025-12-15',
    type: 'feature',
    description: 'Added const keyword for immutable variable declarations'
  },
  {
    hash: 'eb91fedce813780ab3111dde70d7f48edc7a73a8',
    shortHash: 'eb91fed',
    message: 'File Execution',
    date: '2025-12-15',
    type: 'milestone',
    description: 'Vienna can now parse and evaluate .vn files directly'
  },
  {
    hash: 'c08445f9ce8d2c78cba7a65b8702289f5614cfdc',
    shortHash: 'c08445f',
    message: 'Interpreter',
    date: '2025-12-15',
    type: 'milestone',
    description: 'The interpreter is working! Vienna can now execute code'
  },
  {
    hash: 'baea38ef8278abcf0a8c3682683b633dfa1c6ee4',
    shortHash: 'baea38e',
    message: 'Operator Precedence',
    date: '2025-12-15',
    type: 'improvement',
    description: 'Added proper operator precedence to the parser'
  },
  {
    hash: '62dde35e6ab0c7f98cd5b463a3a75ac10bd49286',
    shortHash: '62dde35',
    message: 'String & Boolean Literals',
    date: '2025-12-14',
    type: 'feature',
    description: 'Parser now supports string and boolean literal parsing'
  },
  {
    hash: '588266cf1c96150fb6839f52530dd342273b5c32',
    shortHash: '588266c',
    message: 'Integer Literals',
    date: '2025-12-14',
    type: 'feature',
    description: 'Parser now supports integer literal parsing'
  },
  {
    hash: 'f38948bf30fb13882bf70886d440e8413eb84391',
    shortHash: 'f38948b',
    message: 'Parser Foundation',
    date: '2025-12-14',
    type: 'milestone',
    description: 'Basic parser implementation started'
  },
  {
    hash: '183ec2aefd82fc5fc7f836c7efc9c7bc90184211',
    shortHash: '183ec2a',
    message: 'Lexer Complete',
    date: '2025-12-14',
    type: 'milestone',
    description: 'The lexer is fully functional and can tokenize Vienna source code'
  },
  {
    hash: 'a240fba0541a7f3ed8a8e272d5f611db67a8b8fe',
    shortHash: 'a240fba',
    message: 'Initial Commit',
    date: '2025-12-14',
    type: 'milestone',
    description: 'The Vienna programming language project begins!'
  }
];

const GITHUB_REPO = 'https://github.com/NWBY/viennalang';

function getTypeColor(type: Milestone['type']) {
  switch (type) {
    case 'feature':
      return 'bg-[#27fb6b]';
    case 'milestone':
      return 'bg-purple-500';
    case 'improvement':
      return 'bg-blue-500';
    default:
      return 'bg-gray-500';
  }
}

function getTypeBadgeStyle(type: Milestone['type']) {
  switch (type) {
    case 'feature':
      return 'bg-[#27fb6b]/20 text-[#27fb6b] border-[#27fb6b]/30';
    case 'milestone':
      return 'bg-purple-500/20 text-purple-400 border-purple-500/30';
    case 'improvement':
      return 'bg-blue-500/20 text-blue-400 border-blue-500/30';
    default:
      return 'bg-gray-500/20 text-gray-400 border-gray-500/30';
  }
}

function formatDate(dateStr: string) {
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
}

export default function Timeline() {
  const [filter, setFilter] = useState<'all' | 'feature' | 'milestone' | 'improvement'>('all');

  const filteredMilestones = filter === 'all' 
    ? milestones 
    : milestones.filter(m => m.type === filter);

  return (
    <div className="max-w-4xl mx-auto py-12 px-4">
      <div className="mb-12">
        <h1 className="text-5xl font-bold mb-4 text-[#27fb6b]">Development Status</h1>
        <p className="text-gray-400 text-lg mb-8">
          Track the progress of Vienna's development. Each milestone represents a significant step forward in building this experimental programming language.
        </p>
        
        {/* Filter Buttons */}
        <div className="flex flex-wrap gap-3 mb-8">
          <button
            onClick={() => setFilter('all')}
            className={`px-4 py-2 rounded-lg transition-all duration-200 border ${
              filter === 'all'
                ? 'bg-white/10 border-white/20 text-white'
                : 'border-white/10 text-gray-400 hover:border-white/20 hover:text-white'
            }`}
          >
            All
          </button>
          <button
            onClick={() => setFilter('milestone')}
            className={`px-4 py-2 rounded-lg transition-all duration-200 border ${
              filter === 'milestone'
                ? 'bg-purple-500/20 border-purple-500/30 text-purple-400'
                : 'border-white/10 text-gray-400 hover:border-purple-500/30 hover:text-purple-400'
            }`}
          >
            Milestones
          </button>
          <button
            onClick={() => setFilter('feature')}
            className={`px-4 py-2 rounded-lg transition-all duration-200 border ${
              filter === 'feature'
                ? 'bg-[#27fb6b]/20 border-[#27fb6b]/30 text-[#27fb6b]'
                : 'border-white/10 text-gray-400 hover:border-[#27fb6b]/30 hover:text-[#27fb6b]'
            }`}
          >
            Features
          </button>
          <button
            onClick={() => setFilter('improvement')}
            className={`px-4 py-2 rounded-lg transition-all duration-200 border ${
              filter === 'improvement'
                ? 'bg-blue-500/20 border-blue-500/30 text-blue-400'
                : 'border-white/10 text-gray-400 hover:border-blue-500/30 hover:text-blue-400'
            }`}
          >
            Improvements
          </button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-3 gap-4 mb-12">
          <div className="bg-white/5 border border-white/10 rounded-lg p-4">
            <div className="text-3xl font-bold text-[#27fb6b]">
              {milestones.filter(m => m.type === 'feature').length}
            </div>
            <div className="text-gray-400 text-sm">Features</div>
          </div>
          <div className="bg-white/5 border border-white/10 rounded-lg p-4">
            <div className="text-3xl font-bold text-purple-400">
              {milestones.filter(m => m.type === 'milestone').length}
            </div>
            <div className="text-gray-400 text-sm">Milestones</div>
          </div>
          <div className="bg-white/5 border border-white/10 rounded-lg p-4">
            <div className="text-3xl font-bold text-blue-400">
              {milestones.filter(m => m.type === 'improvement').length}
            </div>
            <div className="text-gray-400 text-sm">Improvements</div>
          </div>
        </div>
      </div>

      {/* Timeline */}
      <div className="relative">
        {/* Vertical Line */}
        <div className="absolute left-4 top-0 bottom-0 w-0.5 bg-gradient-to-b from-[#27fb6b] via-purple-500 to-gray-700"></div>

        <div className="space-y-8">
          {filteredMilestones.map((milestone, index) => (
            <div key={milestone.hash} className="relative pl-12">
              {/* Dot */}
              <div className={`absolute left-2 top-2 w-5 h-5 rounded-full ${getTypeColor(milestone.type)} ring-4 ring-neutral-950`}></div>

              {/* Content Card */}
              <div className="bg-white/5 border border-white/10 rounded-lg p-5 hover:bg-white/[0.07] hover:border-white/20 transition-all duration-200">
                <div className="flex flex-wrap items-start justify-between gap-3 mb-3">
                  <div className="flex flex-wrap items-center gap-3">
                    <h3 className="text-xl font-semibold text-white">{milestone.message}</h3>
                    <span className={`text-xs px-2 py-1 rounded-full border ${getTypeBadgeStyle(milestone.type)}`}>
                      {milestone.type}
                    </span>
                  </div>
                  <span className="text-gray-500 text-sm">{formatDate(milestone.date)}</span>
                </div>
                
                {milestone.description && (
                  <p className="text-gray-400 mb-4">{milestone.description}</p>
                )}

                <div className="flex items-center gap-4">
                  <a
                    href={`${GITHUB_REPO}/commit/${milestone.hash}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 text-sm text-gray-400 hover:text-[#27fb6b] transition-colors"
                  >
                    <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                    </svg>
                    <code className="bg-white/10 px-2 py-0.5 rounded">{milestone.shortHash}</code>
                  </a>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Footer */}
      <div className="mt-16 text-center">
        <p className="text-gray-500 mb-4">Want to contribute?</p>
        <a
          href={GITHUB_REPO}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 bg-[#27fb6b] hover:bg-[#27fb6b]/80 transition-all duration-300 text-neutral-950 px-6 py-3 rounded-lg font-medium"
        >
          <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
            <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
          </svg>
          Star on GitHub
        </a>
      </div>
    </div>
  );
}
