import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:provider/provider.dart';

void main() async {
  await Parse().initialize(
    'wREJj2YEPsluTLseepMZhsjR8BdckByQ48RntNW2',
    'https://parseapi.back4app.com/parse',
    clientKey: 'AlEDzV2Toa00grY7xyQeCKavmsbhdpP5f3h5rU3U',
    autoSendSessionId: true,
    debug: true,
  );
  runApp(MyApp());
}

class Task {
  final String objectId;
  final String title;
  final String description;
  bool isSelected;

  Task({
    required this.objectId,
    required this.title,
    required this.description,
    this.isSelected = false,
  });
}

class TaskModel extends ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  Future<void> fetchTasks() async {
    try {
      var response = await ParseObject('Task').getAll();
      if (response.success && response.results != null) {
        List<Task> tasks = [];
        for (var result in response.results!) {
          tasks.add(Task(
            objectId: result.objectId!,
            title: result.get<String>('title') ?? '',
            description: result.get<String>('description') ?? '',
          ));
        }
        _tasks = tasks;
        notifyListeners();
      } else {
        print('Error fetching tasks: ${response.error!.message}');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
    }
  }

  Future<void> addTask(String title, String description) async {
    try {
      var object = ParseObject('Task')
        ..set('title', title)
        ..set('description', description);

      var response = await object.save();
      if (response.success) {
        fetchTasks();
      } else {
        print('Error adding task: ${response.error!.message}');
      }
    } catch (e) {
      print('Error adding task: $e');
    }
  }

  Future<void> updateTask(
      String objectId, String title, String description) async {
    try {
      var object = ParseObject('Task')..objectId = objectId;
      object.set('title', title);
      object.set('description', description);

      var response = await object.save();
      if (response.success) {
        fetchTasks();
      } else {
        print('Error updating task: ${response.error!.message}');
      }
    } catch (e) {
      print('Error updating task: $e');
    }
  }

  Future<void> deleteTask(String objectId) async {
    try {
      var object = ParseObject('Task')..objectId = objectId;
      var response = await object.delete();
      if (response.success) {
        fetchTasks();
      } else {
        print('Error deleting task: ${response.error!.message}');
      }
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  void clearSelectedTasks() {
    for (var task in _tasks) {
      task.isSelected = false;
    }
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TaskModel(),
      child: MaterialApp(
        title: 'ToDo App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Provider.of<TaskModel>(context, listen: false).fetchTasks();

    return Scaffold(
      appBar: AppBar(
        title: Text('ToDo App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String title = titleController.text;
                String description = descriptionController.text;

                if (title.isNotEmpty && description.isNotEmpty) {
                  await Provider.of<TaskModel>(context, listen: false)
                      .addTask(title, description);
                  titleController.clear();
                  descriptionController.clear();
                }
              },
              child: Text('Add Task'),
            ),
            SizedBox(height: 20),
            TaskList(),
          ],
        ),
      ),
    );
  }
}

class TaskList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TaskModel>(
      builder: (context, taskModel, child) {
        return Expanded(
          child: ListView.builder(
            itemCount: taskModel.tasks.length,
            itemBuilder: (context, index) {
              Task task = taskModel.tasks[index];
              return ListTile(
                onTap: () {
                  _showTaskDetails(context, task);
                },
                leading: Checkbox(
                  value: task.isSelected,
                  onChanged: (value) {
                    task.isSelected = value ?? false;
                    Provider.of<TaskModel>(context, listen: false)
                        .notifyListeners();
                  },
                ),
                title: Text(task.title),
                subtitle: Text(task.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _showEditDialog(context, task);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _showDeleteConfirmation(context, task);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Task task) {
    TextEditingController titleController =
        TextEditingController(text: task.title);
    TextEditingController descriptionController =
        TextEditingController(text: task.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String updatedTitle = titleController.text;
                String updatedDescription = descriptionController.text;

                if (updatedTitle.isNotEmpty && updatedDescription.isNotEmpty) {
                  await Provider.of<TaskModel>(context, listen: false)
                      .updateTask(
                          task.objectId, updatedTitle, updatedDescription);
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Task'),
          content: Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await Provider.of<TaskModel>(context, listen: false)
                    .deleteTask(task.objectId);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Task Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Title: ${task.title}'),
              SizedBox(height: 10),
              Text('Description: ${task.description}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
