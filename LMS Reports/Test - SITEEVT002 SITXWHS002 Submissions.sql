/*
https://lms.upskilled.edu.au/blocks/configurable_reports/editcomp.php?id=261
*/
SELECT Student.Student Student, Student.Course Course,
	CONCAT( Submission.Assessment, ' ~ ', Submission.Time_Submitted, ' ~ ', Submission.Grade ) Assessment,
	Progress.Completion,
	Student.Status
FROM
(
	SELECT DISTINCT
		CONCAT( '<a target="_new" href="%%WWWROOT%%/user/profile.php', CHAR(63), 'id=', u.id, '">', u.firstname, ' ', u.lastname, '</a>' ) Student,
		CONCAT( '<a target="_new" href="%%WWWROOT%%/enrol/users.php', CHAR(63), 'id=', c.id, '">', c.shortname, '</a>') Course,
		CASE
			WHEN ( u.suspended = 0 AND ue.status = 0 AND ue.timeend = '' ) THEN 'Active'
			ELSE 'Inactive'
		END Status,
		CONCAT( u.id, c.id ) Enrolment_Identifier

	FROM prefix_label l
	JOIN prefix_course_modules cm ON cm.instance = l.id AND cm.course = l.course
	JOIN prefix_course c ON c.id = cm.course
	JOIN prefix_course_sections cs ON cs.id = cm.section AND cs.course = cm.course
	JOIN prefix_course_modules cma ON cma.course = cs.course AND cma.section = cs.id AND cma.module = 21
	JOIN prefix_assign a ON a.course = cma.course AND a.id = cma.instance
	JOIN prefix_enrol e ON e.courseid = c.id
	JOIN prefix_user_enrolments ue ON ue.enrolid = e.id
	JOIN prefix_user u ON u.id = ue.userid

	WHERE ( (LOWER(l.intro) REGEXP 'siteevt010') OR (LOWER(l.intro) REGEXP 'sitxwhs002') )
	AND NOT LOWER(l.intro) REGEXP 'instructions|resource - '
	AND TRIM(a.name) REGEXP 'Assessment - (Major Project|Manage Installation|Manage (on-site event operations|Onsite Operations)|Manage Risk|Practical Skills Register|Staging Operations|Identify Hazards )'
) Student
JOIN
(
	SELECT DISTINCT Enrolment_Identifier,
		( Completed_Assessment_Items / (Total_Assessment_Items - CT_Granted - RPL_Granted) ) * 100 Completion

	FROM
	(
		SELECT DISTINCT
			COUNT(gi.iteminstance) Total_Assessment_Items,
			SUM( CASE WHEN ( gg.finalgrade / gg.rawgrademax > 0.70 )
				THEN 1
			ELSE 0
			END ) Completed_Assessment_Items,
			SUM( CASE WHEN gg.finalgrade = 0
				THEN 1
			ELSE 0
			END ) CT_Granted,
			SUM( CASE WHEN gg.finalgrade = 70
				THEN 1
			ELSE 0
			END ) RPL_Granted,
			CONCAT( Student.Sid, c.id ) Enrolment_Identifier

		FROM
		(
			SELECT DISTINCT u.firstname Sfirst, u.lastname Slast, u.id Sid, es.courseid Cid, u.email Email
			FROM prefix_enrol es
			JOIN prefix_user_enrolments ues ON ues.enrolid = es.id
			JOIN prefix_user u ON u.id = ues.userid
			JOIN prefix_role_assignments ras ON ras.userid = u.id AND ras.roleid = 5
			JOIN prefix_context xs ON xs.contextlevel = 50 AND xs.id = ras.contextid AND xs.instanceid = es.courseid
			
			WHERE u.firstname IS NOT NULL
			AND u.lastname IS NOT NULL
			/*AND u.suspended = 0
			AND ues.status = 0
			AND ues.timeend = ''*/
		) Student
		JOIN prefix_course c ON c.id = Student.Cid
		JOIN prefix_grade_items gi ON gi.courseid = c.id AND gi.itemtype = 'mod'
		LEFT JOIN prefix_grade_grades gg ON gg.itemid = gi.id AND gg.userid = Student.Sid
		LEFT JOIN prefix_course_modules cm ON cm.course = c.id AND cm.instance = gi.iteminstance
		
		WHERE LOWER(gi.itemname) LIKE 'assessment -%'
		AND gi.itemname NOT LIKE 'Assessment - IT Foundations Course'
		AND gi.hidden = 0
		AND cm.visible = 1
		AND IFNULL( CASE
						WHEN cm.availability REGEXP '({"op":"[|&]",)("c":\\[){0,1}({"type":"date","d":"(<)","t":[0-9]{1,}},{0,1}){1,}' THEN ( UNIX_TIMESTAMP() < CONVERT( REGEXP_SUBSTR( cm.availability, '[0-9]{1,}' ), UNSIGNED ) )
						WHEN cm.availability REGEXP '({"op":"[|&]",)("c":\\[){0,1}({"type":"date","d":"(>=)","t":[0-9]{1,}},{0,1}){1,}' THEN ( UNIX_TIMESTAMP() >= CONVERT( REGEXP_SUBSTR( cm.availability, '[0-9]{1,}' ), UNSIGNED ) )
						WHEN ( cm.availability REGEXP '({"op":"[|&]",)("showc":\\[[a-z]{1,}\\],){0,1}("c":\\[){0,1}({"type":"profile","sf":"email","op":"(isequalto|contains|endswith)","v":"[\\w.@-]*"},{0,1}){1,}' AND cm.availability REGEXP CONCAT( '"', Student.Email, '"' ) ) THEN 1
						WHEN ( cm.availability REGEXP '({"op":"[|&]",)("showc":\\[[a-z]{1,}\\],){0,1}("c":\\[){0,1}({"type":"profile","sf":"email","op":"(isequalto|contains|endswith)","v":"[\\w.@-]*"},{0,1}){1,}' AND NOT cm.availability REGEXP CONCAT( '"', Student.Email, '"' ) ) THEN 0
						WHEN ( cm.availability REGEXP '({"op":"![|&]",)("showc":\\[[a-z]{1,}\\],){0,1}("c":\\[){0,1}({"type":"profile","sf":"email","op":"(isequalto|contains|endswith)","v":"[\\w.@-]*"},{0,1}){1,}' AND cm.availability REGEXP CONCAT( '"', Student.Email, '"' ) ) THEN 0
						WHEN ( cm.availability REGEXP '({"op":"![|&]",)("showc":\\[[a-z]{1,}\\],){0,1}("c":\\[){0,1}({"type":"profile","sf":"email","op":"(isequalto|contains|endswith)","v":"[\\w.@-]*"},{0,1}){1,}' AND NOT cm.availability REGEXP CONCAT( '"', Student.Email, '"' ) ) THEN 1
						WHEN ( cm.availability REGEXP '({"op":"[|&]",)("showc":\\[[a-z]{1,}\\],){0,1}("c":\\[){0,1}({"type":"profile","sf":"email","op":"(doesnotcontain)","v":"[\\w.@-]*"},{0,1}){1,}' AND cm.availability REGEXP CONCAT( '"', Student.Email, '"' ) ) THEN 0
						WHEN ( cm.availability REGEXP '({"op":"[|&]",)("showc":\\[[a-z]{1,}\\],){0,1}("c":\\[){0,1}({"type":"profile","sf":"email","op":"(doesnotcontain)","v":"[\\w.@-]*"},{0,1}){1,}' AND NOT cm.availability REGEXP CONCAT( '"', Student.Email, '"' ) ) THEN 1
					END, 1 ) = 1

		GROUP BY Student.Sid, c.id
	) Merged
) Progress ON Progress.Enrolment_Identifier = Student.Enrolment_Identifier
LEFT JOIN
(
	SELECT
		CONCAT( '<a target="_new" href="%%WWWROOT%%/mod/assign/view.php', CHAR(63), 'id=', cm.id, '">', gi.itemname, '</a>' ) Assessment,
		gg.finalgrade Grade, FROM_UNIXTIME(gg.timemodified) Time_Graded, FROM_UNIXTIME(asub.timemodified) Time_Submitted, CONCAT( asub.userid, c.id ) Enrolment_Identifier

	FROM prefix_course c
	JOIN prefix_grade_items gi ON gi.courseid = c.id AND gi.itemtype = 'mod'
		AND TRIM(gi.itemname) REGEXP 'Assessment - (Major Project|Manage Installation|Manage (on-site event operations|Onsite Operations)|Manage Risk|Practical Skills Register|Staging Operations|Identify Hazards )'
	JOIN prefix_course_modules cm ON cm.course = c.id AND cm.instance = gi.iteminstance
	JOIN prefix_assign a ON a.name LIKE gi.itemname AND a.course = c.id
	JOIN prefix_assign_submission asub ON asub.assignment = a.id AND asub.latest = 1
	JOIN prefix_grade_grades gg ON gg.itemid = gi.id AND gg.userid = asub.userid
	JOIN prefix_course_sections cs ON cs.id = cm.section AND cs.course = cm.course
	JOIN prefix_course_modules cml ON cml.course = cs.course
	JOIN prefix_label l ON l.id = cml.instance AND l.course = cml.course
		AND ( (LOWER(l.intro) REGEXP 'siteevt010') OR (LOWER(l.intro) REGEXP 'sitxwhs002') )
		AND NOT LOWER(l.intro) REGEXP 'instructions|resource - '

	/*AND gg.finalgrade IS NOT NULL
	AND ( gg.finalgrade = 0 OR gg.finalgrade >= 70 )
	AND asub.status = 'submitted'*/
	WHERE asub.timemodified > UNIX_TIMESTAMP('2019-7-01 00:00:00')
) Submission ON Submission.Enrolment_Identifier = Student.Enrolment_Identifier

HAVING Assessment IS NOT NULL