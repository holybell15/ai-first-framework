window.PROJECT_DASHBOARD_DATA = {
  overview: {
    name: "[專案名稱]",
    type: "[專案類型]",
    tech: "[技術棧]",
    stage: "Discover",
    stageNote: "[進行中的工作描述]",
    updated: "YYYY-MM-DDTHH:MM:SS+08:00"
  },
  pipeline: {
    current: "Discover",
    stages: ["Discover", "Plan", "Build", "Verify", "Ship"]
  },
  tasks: [
    {
      id: "T001",
      feature: "[Feature name]",
      title: "[Task title]",
      size: "M",
      status: "backlog",
      specialist: "[Agent name]",
      evidence: "[Link or note]",
      depends_on: ""
    }
  ],
  gates: {
    discover: {
      items: [
        {
          name: "[Checklist item]",
          pass: false,
          evidence: "[Link or file path]"
        }
      ],
      passed: false
    },
    plan: {
      items: [
        {
          name: "[Checklist item]",
          pass: false,
          evidence: "[Link or file path]"
        }
      ],
      passed: false
    },
    build: {
      items: [
        {
          name: "[Checklist item]",
          pass: false,
          evidence: "[Link or file path]"
        }
      ],
      passed: false
    },
    ship: {
      items: [
        {
          name: "[Checklist item]",
          pass: false,
          evidence: "[Link or file path]"
        }
      ],
      passed: false
    }
  },
  agents: {
    active: "",
    group: ""
  }
};
