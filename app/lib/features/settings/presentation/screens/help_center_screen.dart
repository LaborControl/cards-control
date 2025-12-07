import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class HelpCenterScreen extends StatefulWidget {
  final int initialTab;

  const HelpCenterScreen({super.key, this.initialTab = 0});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpCenter),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.question_answer),
              text: l10n.faq,
            ),
            Tab(
              icon: const Icon(Icons.play_circle_outline),
              text: l10n.tutorials,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FaqTab(),
          _TutorialsTab(),
        ],
      ),
    );
  }
}

// ==================== FAQ TAB ====================

class _FaqTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final faqCategories = [
      _FaqCategory(
        title: l10n.faqGeneralTitle,
        icon: Icons.info_outline,
        color: AppColors.primary,
        questions: [
          _FaqItem(
            question: l10n.faqWhatIsNfc,
            answer: l10n.faqWhatIsNfcAnswer,
          ),
          _FaqItem(
            question: l10n.faqCompatibility,
            answer: l10n.faqCompatibilityAnswer,
          ),
          _FaqItem(
            question: l10n.faqTagTypes,
            answer: l10n.faqTagTypesAnswer,
          ),
        ],
      ),
      _FaqCategory(
        title: l10n.faqReadWriteTitle,
        icon: Icons.nfc,
        color: AppColors.secondary,
        questions: [
          _FaqItem(
            question: l10n.faqHowToRead,
            answer: l10n.faqHowToReadAnswer,
          ),
          _FaqItem(
            question: l10n.faqHowToWrite,
            answer: l10n.faqHowToWriteAnswer,
          ),
          _FaqItem(
            question: l10n.faqWriteFailed,
            answer: l10n.faqWriteFailedAnswer,
          ),
          _FaqItem(
            question: l10n.faqLockTag,
            answer: l10n.faqLockTagAnswer,
          ),
        ],
      ),
      _FaqCategory(
        title: l10n.faqCardsTitle,
        icon: Icons.contact_page,
        color: AppColors.tertiary,
        questions: [
          _FaqItem(
            question: l10n.faqCreateCard,
            answer: l10n.faqCreateCardAnswer,
          ),
          _FaqItem(
            question: l10n.faqShareCard,
            answer: l10n.faqShareCardAnswer,
          ),
          _FaqItem(
            question: l10n.faqScanBusinessCard,
            answer: l10n.faqScanBusinessCardAnswer,
          ),
        ],
      ),
      _FaqCategory(
        title: l10n.faqEmulationTitle,
        icon: Icons.smartphone,
        color: AppColors.info,
        questions: [
          _FaqItem(
            question: l10n.faqWhatIsHce,
            answer: l10n.faqWhatIsHceAnswer,
          ),
          _FaqItem(
            question: l10n.faqHceRequirements,
            answer: l10n.faqHceRequirementsAnswer,
          ),
          _FaqItem(
            question: l10n.faqHceLimits,
            answer: l10n.faqHceLimitsAnswer,
          ),
        ],
      ),
      _FaqCategory(
        title: l10n.faqTemplatesTitle,
        icon: Icons.description,
        color: Colors.teal,
        questions: [
          _FaqItem(
            question: l10n.faqWhatAreTemplates,
            answer: l10n.faqWhatAreTemplatesAnswer,
          ),
          _FaqItem(
            question: l10n.faqCreateTemplate,
            answer: l10n.faqCreateTemplateAnswer,
          ),
          _FaqItem(
            question: l10n.faqShareTemplate,
            answer: l10n.faqShareTemplateAnswer,
          ),
        ],
      ),
      _FaqCategory(
        title: l10n.faqAiTitle,
        icon: Icons.auto_awesome,
        color: Colors.deepPurple,
        questions: [
          _FaqItem(
            question: l10n.faqWhatIsAi,
            answer: l10n.faqWhatIsAiAnswer,
          ),
          _FaqItem(
            question: l10n.faqAiCredits,
            answer: l10n.faqAiCreditsAnswer,
          ),
          _FaqItem(
            question: l10n.faqAiExtractContact,
            answer: l10n.faqAiExtractContactAnswer,
          ),
        ],
      ),
      _FaqCategory(
        title: l10n.faqFormatTitle,
        icon: Icons.delete_sweep,
        color: Colors.red,
        questions: [
          _FaqItem(
            question: l10n.faqWhatIsFormat,
            answer: l10n.faqWhatIsFormatAnswer,
          ),
          _FaqItem(
            question: l10n.faqFormatVsWrite,
            answer: l10n.faqFormatVsWriteAnswer,
          ),
          _FaqItem(
            question: l10n.faqFormatSafe,
            answer: l10n.faqFormatSafeAnswer,
          ),
        ],
      ),
      _FaqCategory(
        title: l10n.faqTroubleshootingTitle,
        icon: Icons.build,
        color: Colors.orange,
        questions: [
          _FaqItem(
            question: l10n.faqNfcNotWorking,
            answer: l10n.faqNfcNotWorkingAnswer,
          ),
          _FaqItem(
            question: l10n.faqTagNotDetected,
            answer: l10n.faqTagNotDetectedAnswer,
          ),
          _FaqItem(
            question: l10n.faqDataLoss,
            answer: l10n.faqDataLossAnswer,
          ),
        ],
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqCategories.length,
      itemBuilder: (context, index) {
        final category = faqCategories[index];
        return _FaqCategoryCard(category: category);
      },
    );
  }
}

class _FaqCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<_FaqItem> questions;

  _FaqCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.questions,
  });
}

class _FaqItem {
  final String question;
  final String answer;

  _FaqItem({required this.question, required this.answer});
}

class _FaqCategoryCard extends StatelessWidget {
  final _FaqCategory category;

  const _FaqCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.icon, color: category.color, size: 24),
          ),
          title: Text(
            category.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: category.questions.map((faq) {
            return _FaqQuestionTile(faq: faq);
          }).toList(),
        ),
      ),
    );
  }
}

class _FaqQuestionTile extends StatelessWidget {
  final _FaqItem faq;

  const _FaqQuestionTile({required this.faq});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          faq.question,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                faq.answer,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== TUTORIALS TAB ====================

class _TutorialsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final tutorials = [
      _Tutorial(
        title: l10n.tutorialGettingStarted,
        description: l10n.tutorialGettingStartedDesc,
        icon: Icons.rocket_launch,
        color: AppColors.primary,
        steps: [
          l10n.tutorialStep1Enable,
          l10n.tutorialStep2Open,
          l10n.tutorialStep3Place,
          l10n.tutorialStep4Read,
        ],
      ),
      _Tutorial(
        title: l10n.tutorialReadTag,
        description: l10n.tutorialReadTagDesc,
        icon: Icons.nfc,
        color: AppColors.secondary,
        steps: [
          l10n.tutorialReadStep1,
          l10n.tutorialReadStep2,
          l10n.tutorialReadStep3,
          l10n.tutorialReadStep4,
        ],
      ),
      _Tutorial(
        title: l10n.tutorialWriteTag,
        description: l10n.tutorialWriteTagDesc,
        icon: Icons.edit,
        color: AppColors.tertiary,
        steps: [
          l10n.tutorialWriteStep1,
          l10n.tutorialWriteStep2,
          l10n.tutorialWriteStep3,
          l10n.tutorialWriteStep4,
          l10n.tutorialWriteStep5,
        ],
      ),
      _Tutorial(
        title: l10n.tutorialCreateCard,
        description: l10n.tutorialCreateCardDesc,
        icon: Icons.contact_page,
        color: AppColors.info,
        steps: [
          l10n.tutorialCardStep1,
          l10n.tutorialCardStep2,
          l10n.tutorialCardStep3,
          l10n.tutorialCardStep4,
        ],
      ),
      _Tutorial(
        title: l10n.tutorialEmulation,
        description: l10n.tutorialEmulationDesc,
        icon: Icons.smartphone,
        color: Colors.purple,
        steps: [
          l10n.tutorialEmulateStep1,
          l10n.tutorialEmulateStep2,
          l10n.tutorialEmulateStep3,
          l10n.tutorialEmulateStep4,
        ],
        isPro: true,
      ),
      _Tutorial(
        title: l10n.tutorialCopyTag,
        description: l10n.tutorialCopyTagDesc,
        icon: Icons.copy,
        color: Colors.teal,
        steps: [
          l10n.tutorialCopyStep1,
          l10n.tutorialCopyStep2,
          l10n.tutorialCopyStep3,
          l10n.tutorialCopyStep4,
        ],
        isPro: true,
      ),
      _Tutorial(
        title: l10n.tutorialTemplates,
        description: l10n.tutorialTemplatesDesc,
        icon: Icons.description,
        color: Colors.indigo,
        steps: [
          l10n.tutorialTemplateStep1,
          l10n.tutorialTemplateStep2,
          l10n.tutorialTemplateStep3,
          l10n.tutorialTemplateStep4,
          l10n.tutorialTemplateStep5,
        ],
      ),
      _Tutorial(
        title: l10n.tutorialAiAnalysis,
        description: l10n.tutorialAiAnalysisDesc,
        icon: Icons.auto_awesome,
        color: Colors.deepPurple,
        steps: [
          l10n.tutorialAiStep1,
          l10n.tutorialAiStep2,
          l10n.tutorialAiStep3,
          l10n.tutorialAiStep4,
        ],
      ),
      _Tutorial(
        title: l10n.tutorialFormatTag,
        description: l10n.tutorialFormatTagDesc,
        icon: Icons.delete_sweep,
        color: Colors.red,
        steps: [
          l10n.tutorialFormatStep1,
          l10n.tutorialFormatStep2,
          l10n.tutorialFormatStep3,
          l10n.tutorialFormatStep4,
        ],
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tutorials.length,
      itemBuilder: (context, index) {
        final tutorial = tutorials[index];
        return _TutorialCard(tutorial: tutorial);
      },
    );
  }
}

class _Tutorial {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> steps;
  final bool isPro;

  _Tutorial({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.steps,
    this.isPro = false,
  });
}

class _TutorialCard extends StatelessWidget {
  final _Tutorial tutorial;

  const _TutorialCard({required this.tutorial});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tutorial.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tutorial.icon, color: tutorial.color, size: 28),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  tutorial.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (tutorial.isPro)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.pro,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            tutorial.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  ...tutorial.steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    return _StepItem(
                      number: index + 1,
                      text: step,
                      color: tutorial.color,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int number;
  final String text;
  final Color color;

  const _StepItem({
    required this.number,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
