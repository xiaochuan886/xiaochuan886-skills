#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { spawnSync } = require("child_process");

function printHelp() {
  console.log(`OPC Community Writer workflow runner

Usage:
  run-workflow.js [--step init] --topic "一人公司"
  run-workflow.js --step status --dir /path/to/task
  run-workflow.js --step plan-images --dir /path/to/task
  run-workflow.js --step validate-images --dir /path/to/task
  run-workflow.js --step validate-research --dir /path/to/task
  run-workflow.js --step validate-xhs --dir /path/to/task
  run-workflow.js --step validate --dir /path/to/task
  run-workflow.js --step sanitize --dir /path/to/task
`);
}

function parseArgs(argv) {
  const options = { step: "init", force: false };
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    switch (token) {
      case "--step":
        options.step = argv[++index];
        break;
      case "--topic":
        options.topic = argv[++index];
        break;
      case "--column":
        options.column = argv[++index];
        break;
      case "--author":
        options.author = argv[++index];
        break;
      case "--root":
        options.root = argv[++index];
        break;
      case "--date":
        options.date = argv[++index];
        break;
      case "--task-name":
        options.taskName = argv[++index];
        break;
      case "--dir":
        options.dir = argv[++index];
        break;
      case "--output":
        options.output = argv[++index];
        break;
      case "--in-place":
        options.inPlace = true;
        break;
      case "--force":
        options.force = true;
        break;
      case "-h":
      case "--help":
        options.help = true;
        break;
      default:
        throw new Error(`Unknown argument: ${token}`);
    }
  }
  return options;
}

function runCommand(command, args) {
  return spawnSync(command, args, {
    encoding: "utf8",
    stdio: ["inherit", "pipe", "pipe"],
  });
}

function extractBody(articleText) {
  if (!articleText.startsWith("---\n")) return articleText;
  const end = articleText.indexOf("\n---\n", 4);
  if (end === -1) return articleText;
  return articleText.slice(end + 5);
}

function collectMarkdownImagePaths(text) {
  const matches = [...text.matchAll(/!\[[^\]]*\]\(([^)]+)\)/g)];
  return matches.map((match) => match[1]);
}

function resolvePath(baseDir, targetPath) {
  if (path.isAbsolute(targetPath)) return targetPath;
  const cleaned = targetPath.startsWith("./") ? targetPath.slice(2) : targetPath;
  return path.join(baseDir, cleaned);
}

function renderStatus(taskDir) {
  const articlePath = path.join(taskDir, "article.md");
  const xhsPath = path.join(taskDir, "xhs.md");
  const researchPath = path.join(taskDir, "research.md");
  const topicsPath = path.join(taskDir, "topics.md");
  const imagesDir = path.join(taskDir, "imgs");

  console.log(`Task directory: ${taskDir}`);
  console.log(`- research.md: ${fs.existsSync(researchPath) ? "present" : "missing"}`);
  console.log(`- topics.md: ${fs.existsSync(topicsPath) ? "present" : "missing"}`);
  console.log(`- article.md: ${fs.existsSync(articlePath) ? "present" : "missing"}`);
  console.log(`- xhs.md: ${fs.existsSync(xhsPath) ? "present" : "missing"}`);
  console.log(`- imgs/: ${fs.existsSync(imagesDir) ? "present" : "missing"}`);

  if (!fs.existsSync(articlePath)) return;

  const articleText = fs.readFileSync(articlePath, "utf8");
  const bodyText = extractBody(articleText);
  const bodyImages = collectMarkdownImagePaths(bodyText);
  const urlMatches = articleText.match(/https?:\/\/|www\./g) || [];

  console.log(`- body image refs: ${bodyImages.length}`);
  console.log(`- url matches: ${urlMatches.length}`);

  const coverMatch = articleText.match(/^coverImage:\s*(.+)$/m);
  if (coverMatch) {
    const coverPath = coverMatch[1].trim().replace(/^['"]|['"]$/g, "");
    const resolvedCover = resolvePath(taskDir, coverPath);
    console.log(`- cover image file: ${fs.existsSync(resolvedCover) ? "present" : "missing"}`);
  }
}

function main() {
  let options;
  try {
    options = parseArgs(process.argv.slice(2));
  } catch (error) {
    console.error(error.message);
    printHelp();
    process.exit(1);
  }

  if (options.help) {
    printHelp();
    return;
  }

  const scriptDir = __dirname;
  const initScript = path.join(scriptDir, "init-article-dir.sh");
  const imagesPlanScript = path.join(scriptDir, "generate-images-plan.sh");
  const validateImagesScript = path.join(scriptDir, "validate-images-plan.sh");
  const validateResearchScript = path.join(scriptDir, "validate-research.sh");
  const validateArticleScript = path.join(scriptDir, "validate-article.sh");
  const validateXhsScript = path.join(scriptDir, "validate-xhs.sh");
  const sanitizeScript = path.join(scriptDir, "sanitize-article.sh");

  if (options.step === "init") {
    const args = [initScript, "--print-path-only"];
    if (options.topic) args.push("--topic", options.topic);
    if (options.column) args.push("--column", options.column);
    if (options.author) args.push("--author", options.author);
    if (options.root) args.push("--root", options.root);
    if (options.date) args.push("--date", options.date);
    if (options.taskName) args.push("--task-name", options.taskName);
    if (options.force) args.push("--force");

    const result = runCommand("bash", args);
    if (result.status !== 0) {
      process.stdout.write(result.stdout || "");
      process.stderr.write(result.stderr || "");
      process.exit(result.status || 1);
    }

    const createdDir = (result.stdout || "").trim().split(/\n/).filter(Boolean).pop();
    console.log(`Initialized task: ${createdDir}`);
    renderStatus(createdDir);
    console.log("Next steps:");
    console.log(`1. Fill ${path.join(createdDir, "research.md")} with current findings.`);
    console.log(`2. Draft candidates in ${path.join(createdDir, "topics.md")}.`);
    console.log(`3. Write the article in ${path.join(createdDir, "article.md")}.`);
    console.log(`4. Derive ${path.join(createdDir, "xhs.md")} from the main article.`);
    console.log(`5. Finalize ${path.join(createdDir, "images-plan.md")} and generate images.`);
    console.log(`6. Run: ${path.join(scriptDir, "run-workflow.js")} --step validate --dir ${createdDir}`);
    return;
  }

  if (!options.dir) {
    console.error("--dir is required for this step.");
    process.exit(1);
  }

  const taskDir = path.resolve(options.dir);

  if (options.step === "status") {
    renderStatus(taskDir);
    return;
  }

  if (options.step === "plan-images") {
    const result = runCommand("bash", [imagesPlanScript, "--dir", taskDir, "--force"]);
    process.stdout.write(result.stdout || "");
    process.stderr.write(result.stderr || "");
    process.exit(result.status || 0);
  }

  if (options.step === "validate-images") {
    const result = runCommand("bash", [validateImagesScript, "--dir", taskDir]);
    process.stdout.write(result.stdout || "");
    process.stderr.write(result.stderr || "");
    process.exit(result.status || 0);
  }

  if (options.step === "validate-research") {
    const result = runCommand("bash", [validateResearchScript, "--dir", taskDir]);
    process.stdout.write(result.stdout || "");
    process.stderr.write(result.stderr || "");
    process.exit(result.status || 0);
  }

  if (options.step === "validate-xhs") {
    const result = runCommand("bash", [validateXhsScript, "--dir", taskDir]);
    process.stdout.write(result.stdout || "");
    process.stderr.write(result.stderr || "");
    process.exit(result.status || 0);
  }

  if (options.step === "validate") {
    const checks = [
      [validateResearchScript, "--dir", taskDir],
      [validateArticleScript, "--dir", taskDir],
      [validateXhsScript, "--dir", taskDir],
      [validateImagesScript, "--dir", taskDir],
    ];

    let failed = false;
    for (const [script, flag, dir] of checks) {
      const result = runCommand("bash", [script, flag, dir]);
      process.stdout.write(result.stdout || "");
      process.stderr.write(result.stderr || "");
      if (result.status !== 0) failed = true;
    }
    process.exit(failed ? 1 : 0);
  }

  if (options.step === "sanitize") {
    const args = [sanitizeScript, "--dir", taskDir];
    if (options.output) args.push("--output", path.resolve(options.output));
    if (options.inPlace) args.push("--in-place");
    const result = runCommand("bash", args);
    process.stdout.write(result.stdout || "");
    process.stderr.write(result.stderr || "");
    process.exit(result.status || 0);
  }

  console.error(`Unsupported step: ${options.step}`);
  process.exit(1);
}

main();
