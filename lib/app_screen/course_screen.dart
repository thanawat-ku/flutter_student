import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../model/course.dart';

class CourseScreen extends StatefulWidget {

  const CourseScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CourseScreenState();
  }
}

class _CourseScreenState extends State<CourseScreen> {
  // กำนหดตัวแปรข้อมูล courses
  late Future<List<Course>> courses;

  @override
  void initState() {
    print("initState"); // สำหรับทดสอบ
    super.initState();
    courses = fetchCourses();
  }

  void _refreshData() {
    setState(() {
      print("setState"); // สำหรับทดสอบ
      courses = fetchCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    print("build"); // สำหรับทดสอบ
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        ],
      ),
      body: Center(
        child: FutureBuilder<List<Course>>(
          // ชนิดของข้อมูล
          future: courses, // ข้อมูล Future
          builder: (context, snapshot) {
            print("builder"); // สำหรับทดสอบ
            print(snapshot.connectionState); // สำหรับทดสอบ
            // กรณีสถานะเป็น waiting ยังไม่มีข้อมูล แสดงตัว loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasData) {
              // กรณีมีข้อมูล
              return Column(
                children: [
                  Container(
                    // สร้างส่วน header ของลิสรายการ
                    padding: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      color: Colors.teal.withAlpha(100),
                    ),
                    child: Row(
                      children: [
                        Text(
                            'Total ${snapshot.data!.length} items'), // แสดงจำนวนรายการ
                      ],
                    ),
                  ),
                  Expanded(
                    // ส่วนของลิสรายการ
                    child: snapshot.data!.isNotEmpty // กำหนดเงื่อนไขตรงนี้
                        ? ListView.separated(
                            // กรณีมีรายการ แสดงปกติ
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(snapshot.data![index].courseName),
                                subtitle:
                                    Text(snapshot.data![index].courseCode),
                                trailing: Wrap(
                                  children: [
                                    IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.edit)),
                                    IconButton(
                                        onPressed: () async {
                                          await showDialog(
                                              context: context,
                                              builder: (BuildContext context) =>
                                                  AlertDialog(
                                                    title:
                                                        const Text('Confirm Delete'),
                                                    content: Expanded(
                                                      child: Text(
                                                          "Do you want to delete: ${snapshot
                                                                  .data![index]
                                                                  .courseCode}"),
                                                    ),
                                                    actions: <Widget>[
                                                      TextButton(
                                                          style: TextButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                Colors.white,
                                                            backgroundColor:
                                                                Colors
                                                                    .redAccent,
                                                          ),
                                                          onPressed: () async{
                                                            await deleteCourse(snapshot
                                                                  .data![index]); 
                                                                  setState(() {
                                                                    courses=fetchCourses();
                                                                  });                                                         
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text('Delete')),
                                                      TextButton(
                                                          style: TextButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                Colors.white,
                                                            backgroundColor:
                                                                Colors.blueGrey,
                                                          ),
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text('Close')),
                                                    ],
                                                  ));
                                        },
                                        icon: const Icon(Icons.delete)),
                                  ],
                                ),
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const Divider(),
                          )
                        : const Center(
                            child: Text('No items')), // กรณีไม่มีรายการ
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              // กรณี error
              return Text('${snapshot.error}');
            }
            // กรณีสถานะเป็น waiting ยังไม่มีข้อมูล แสดงตัว loading
            return const CircularProgressIndicator();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // ปุ่มทดสอบสำหรับดึงข้อมูลซ้ำ
        onPressed: _refreshData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// สรัางฟังก์ชั่นดึงข้อมูล คืนค่ากลับมาเป็นข้อมูล Future ประเภท List ของ Course
Future<List<Course>> fetchCourses() async {
  // ทำการดึงข้อมูลจาก server ตาม url ที่กำหนด
  final response =
      await http.get(Uri.parse('http://192.168.1.2:8000/course.php'));

  // เมื่อมีข้อมูลกลับมา
  if (response.statusCode == 200) {
    // ส่งข้อมูลที่เป็น JSON String data ไปทำการแปลง เป็นข้อมูล List<Course
    // โดยใช้คำสั่ง compute ทำงานเบื้องหลัง เรียกใช้ฟังก์ชั่นชื่อ parsecourses
    // ส่งข้อมูล JSON String data ผ่านตัวแปร response.body
    return compute(parseCourses, response.body);
  } else {
    // กรณี error
    throw Exception('Failed to load Course');
  }
}

Future<int> deleteCourse(Course course) async {
  final response = await http.delete(
    Uri.parse(
        'http://192.168.1.2:8000/course.php?course_code=${course.courseCode}'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return response.statusCode;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to update course.');
  }
}


Future<int> updateCourse(Course course) async {
  final response = await http.put(
    Uri.parse(
        'http://192.168.1.4:8000/course.php?course_code=${course.courseCode}'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'course_name': course.courseName,
      'credit': course.credit.toString(),
    }),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return response.statusCode;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to update course.');
  }
}

// ฟังก์ชั่นแปลงข้อมูล JSON String data เป็น เป็นข้อมูล List<Course>
List<Course> parseCourses(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Course>((json) => Course.fromJson(json)).toList();
}
