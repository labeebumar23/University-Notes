import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';

class MockData {
  MockData._();

  static const List<SemesterData> semesters = [
    SemesterData(
      id: 'sem-3',
      title: 'Semester 3',
      status: 'In Progress',
      term: 'Fall 2024 - Spring 2025',
      subjectsPreview: ['CS 301 Data Structs', 'MATH 240 Stats', '+4 more'],
      syllabusCompletion: 0.68,
      subjectCount: 6,
      fileCount: 38,
      fileLabel: 'Lecture Files',
      isLiveSynced: true,
      icon: Icons.school,
      isCurrent: true,
      iconBgColor: AppColors.royalBlue,
      iconColor: Colors.white,
    ),
    SemesterData(
      id: 'sem-4',
      title: 'Semester 4',
      status: 'Upcoming',
      term: 'Starts August 2025',
      subjectsPreview: ['CS 420 AI Systems', 'CS 380 Networks'],
      subjectCount: 5,
      fileCount: 4,
      fileLabel: 'Syllabi Ready',
      icon: Icons.event_upcoming,
      isCurrent: false,
      iconBgColor: AppColors.surfaceHigh,
      iconColor: AppColors.onSurfaceVariant,
    ),
    SemesterData(
      id: 'sem-2',
      title: 'Semester 2',
      status: 'Completed',
      gpa: 'GPA 3.9',
      term: 'Spring 2024',
      subjectsPreview: ['Calculus II', 'OOP in Java', 'Physics II'],
      subjectCount: 6,
      fileCount: 32,
      fileLabel: 'Archived Files',
      icon: Icons.verified,
      isCurrent: false,
      iconBgColor: AppColors.surfaceLow,
      iconColor: AppColors.secondary,
    ),
    SemesterData(
      id: 'sem-1',
      title: 'Semester 1',
      status: 'Completed',
      gpa: 'GPA 3.8',
      term: 'Fall 2023',
      subjectsPreview: ['Calculus I', 'Intro to CS', 'Physics I'],
      subjectCount: 5,
      fileCount: 24,
      fileLabel: 'Archived Files',
      icon: Icons.verified,
      isCurrent: false,
      iconBgColor: AppColors.surfaceLow,
      iconColor: AppColors.secondary,
    ),
  ];

  static const List<SubjectData> subjects = [
    SubjectData(
      code: 'CS101',
      name: 'Programming Fundamentals',
      professor: 'Dr. Marcus Vance • Mon/Wed 10:00 AM',
      schedule: 'Mon/Wed 10:00 AM',
      pdfCount: 14,
      aiNotesCount: 10,
      recentStatus: 'Lecture 12 recorded yesterday',
      recentStatusIcon: Icons.history,
      icon: Icons.terminal,
      iconBg: AppColors.primaryFixed,
      iconColor: AppColors.royalBlue,
      hasPulse: true,
      category: 'active',
    ),
    SubjectData(
      code: 'MATH201',
      name: 'Calculus & Analytical Geometry',
      professor: 'Prof. Elena Rostova • Tue/Thu 02:00 PM',
      schedule: 'Tue/Thu 02:00 PM',
      pdfCount: 12,
      aiNotesCount: 8,
      recentStatus: 'Exam 2 Review AI Summary available',
      recentStatusIcon: Icons.bolt,
      badge: 'Exam Prep',
      icon: Icons.calculate,
      iconBg: AppColors.tertiaryFixed,
      iconColor: AppColors.tertiaryContainer,
      category: 'ai',
    ),
    SubjectData(
      code: 'EE204',
      name: 'Digital Logic Design',
      professor: 'Dr. Kevin Zhao • Fri 09:00 AM',
      schedule: 'Fri 09:00 AM',
      pdfCount: 11,
      aiNotesCount: 6,
      recentStatus: 'Lab 4 Slides + 2hr Lecture Note',
      recentStatusIcon: Icons.layers_outlined,
      icon: Icons.memory,
      iconBg: AppColors.secondaryFixed,
      iconColor: AppColors.secondary,
      category: 'active',
    ),
    SubjectData(
      code: 'CS202',
      name: 'Data Structures & Algorithms',
      professor: 'Prof. Anita Sharma • Tue/Thu 11:30 AM',
      schedule: 'Tue/Thu 11:30 AM',
      pdfCount: 16,
      aiNotesCount: 12,
      recentStatus: 'Graph Algorithms 2-Hour Audio processed',
      recentStatusIcon: Icons.graphic_eq,
      badge: 'Core',
      icon: Icons.account_tree,
      iconBg: AppColors.primaryFixed,
      iconColor: AppColors.royalBlue,
      category: 'ai',
    ),
  ];

  static const List<LectureItemData> lectures = [
    LectureItemData(
      id: 'lec-14',
      lectureNumber: 'Lecture 14',
      title: 'Lecture 14: AVL Trees & Balance Factors',
      duration: '01:54:10',
      date: 'Today, 10:15 AM • Auditory 2A',
      summary:
          'Rotations (LL, RR, LR, RL) restore O(log n) worst-case search time whenever balance factor departs from [-1, 0, 1].',
      keyTakeaway:
          'Rotations (LL, RR, LR, RL) restore O(log n) worst-case search time whenever balance factor departs from [-1, 0, 1].',
      isBookmarked: true,
    ),
    LectureItemData(
      id: 'lec-13',
      lectureNumber: 'Lecture 13',
      title: 'Lecture 13: Binary Search Trees & Deletion',
      duration: '01:48:32',
      date: 'Oct 24, 2024',
      summary:
          'Three deletion scenarios examined: Leaf node, one-child node, and the two-children node replacement using in-order successor.',
      flashcardsCount: '4 Practice Flashcards ready',
      isBookmarked: false,
    ),
  ];

  static const List<PdfItemData> pdfs = [
    PdfItemData(
      title: 'Week 7 - Balanced Trees Slides.pdf',
      size: '4.2 MB',
      addedDate: 'Added yesterday',
      tag: 'Synced',
      tagColor: AppColors.tertiaryContainer,
      icon: Icons.picture_as_pdf,
      iconBg: AppColors.errorContainer,
      iconColor: AppColors.error,
    ),
    PdfItemData(
      title: 'Assignment 3 Problem Set.pdf',
      size: '1.8 MB',
      addedDate: 'Added Oct 22',
      tag: 'Due in 3d',
      tagColor: AppColors.error,
      icon: Icons.assignment_outlined,
      iconBg: AppColors.secondaryContainer,
      iconColor: AppColors.onSecondaryContainer,
    ),
    PdfItemData(
      title: 'Midterm Exam Study Guide & Formula Sheet.pdf',
      size: '8.5 MB',
      addedDate: 'Added Oct 20',
      tag: 'High Yield',
      tagColor: AppColors.royalBlue,
      icon: Icons.menu_book,
      iconBg: AppColors.primaryFixed,
      iconColor: AppColors.royalBlue,
    ),
  ];

  static const List<ExamQuestionData> examQuestions = [
    ExamQuestionData(
      question: 'Q1: How to determine if a Left-Right (LR) rotation is required?',
      answer:
          'An LR rotation is demanded when a node\'s Balance Factor is +2 (heavy on left) and its left child\'s Balance Factor is -1 (heavy on right). This indicates an \'inner elbow\' kink.',
      solutionOrTakeaway:
          'Solution: Rotate Left on child, then Rotate Right on parent.',
      replayTimestamp: '00:42:15',
      isExpandedByDefault: true,
    ),
    ExamQuestionData(
      question: 'Q2: What is the maximum height of an AVL tree with n nodes?',
      answer:
          'The maximum height is strictly bounded by ~1.44 log₂(n). This represents the worst-case Fibonacci-structured tree where every subtree has an alternating balance factor of ±1.',
      solutionOrTakeaway:
          'Takeaway: Search complexity remains guaranteed O(log n).',
      replayTimestamp: '01:05:40',
      isExpandedByDefault: false,
    ),
    ExamQuestionData(
      question:
          'Q3: Compare Red-Black Trees vs AVL Trees for lookup heavy workloads',
      answer:
          'AVL Trees are more rigidly balanced than Red-Black Trees (height factor 1.44 vs 2.0). Consequently, AVL trees yield faster lookups, making them superior for read-dominant caches, while Red-Black trees excel when frequent insertions/deletions occur.',
      solutionOrTakeaway:
          'Exam Tip: Memorize the lookup vs insert tradeoff matrix.',
      replayTimestamp: '01:38:10',
      isExpandedByDefault: false,
    ),
  ];
}

