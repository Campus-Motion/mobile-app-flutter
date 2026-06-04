# CampusMotion Mobile app

This repository is dedicated to the development and research done for the CampusMotion mobile app. It is built using Flutter and makes the app available on Android, iOS, Web, and much more.

## Our goal

Our goal through this app is to make sport and technological advancements made on campus available to all the members of EPFL and UNIL, so that we can all evolve in a moving, healthy community. We are aiming to make the students meet and push themselves together to keep themselves in shape and grow both physically and mentally.
This app is, for now, aimed around the connected trail that we want to build around campus. But it also adds weekly events organized by students, the possibility to track your own activities, and doing so in a secured environment.
This app aims to respect students' health data, which is why it relies on our own GDPR compliant database and aims to display information kept as transparently as possible. Students should be easily able to see, manage and delete any information regarding their health or personal details. Furthermore, they should always be made aware of any treatment/sharing of their data.

## How to start working on this project

Although the role of developer has, for now, only been reserved for students who have taken a software engineering course at EPFL before (like SwEnt or MIT for IC students), we truly believe this project is available to any student with a solid programming knowledge and desire to create something unique. To get started, here are the things you should know about how to work on a larger-scale project and how not to mess up collaboration during development : 

1. Think about what you want to implement **before** starting
    This can sound quite trivial, but just adding random stuff is not going to make the project advance any further or improve it. If you have an idea, think about it, ask your teammates, and if they approve, go forward.
2. Work with git branches
    Git branches are the core of parallel development. They are essentially a ramification of your project from the main, current version of the project. When working on a branch, you are essentially working in isolation, but on the same project as everyone else. They are very handy to make sure that developers don't overlap work, avoid useless merge conflicts, and overall allows other developers to get a general sense of who is working on what.
    > Note : git branches have naming conventions, which you should read and apply !
    To create a branch, simply type : 
    ```
    git checkout -b "<branch_type>/<aim_of_your_branch>"
    ```
    at the root of your project. Make sure you have pulled your code before that !

    **DO NOT PUSH THINGS ON THE MAIN BRANCH DIRECTLY.**

3. Commit your work at the end of every small task
    Kind of like the "don't forget to save your work" type of message, commits should be done very frequently on your newly-created branch. My personal rule is : if you can say to a friend "btw I did that", you should create a commit, no matter the size of the task. This will make your work clearer. You can also push your code after finishing slightly bigger tasks.

4. Make a pull request once you think your work can be added to the project
    Once you are done with your task, you should create a **pull request**. 
    *How ? Why ?*
     Very good questions ! If you go on the github page corresponding to this repository, you will see at the top an option named "pull requests". Upon clicking on it, you will be able to select your branch and then be led to page that lets you describe what you did on your branch.
     **This is crucial for other developers on the project :** state everything you did, why, what it changes, and how you can test it. This is important because, in theory, someone else is going to end working around/with your code. Keeping track of when things changed and for what reasons is crucial. Moreover, this allows other coders to ask you to change code or spot logical errors in your code, so it always come out better.
     Add as much information as you see fit, including screenshots, videos of demo, what should be done next, what limitations your implementation might have, what other developers must add to be able to work on the project, etc...

5. Test what you have done
    Probably the most boring part, but having some tests is always useful. Try writing some, you never know if you could run in a bug, or 2, or 10000.

**What not to do**
1. Post secrets in the repo
    If you handle API keys, secrets, and other stuff related to health data : ask someone that knows how to handle this properly before doing anything. Always store the API keys locally in a .env file, never EVER push it, and we should be golden. You can find ways to push secrets on github online and you'll see it is very easy.

2. Steal other people's work
   
3. Neglect project structure
    Where the files are and how you move around the project is objectively so much more important than the code itself. Try to keep a map of where everything is, coding something twice is sub-optimal.

## Getting Started  with Flutter

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
