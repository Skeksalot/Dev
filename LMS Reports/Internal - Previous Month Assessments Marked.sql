/*
https://lms.upskilled.edu.au/blocks/configurable_reports/viewreport.php?id=268
*/

SELECT DISTINCT
	CONCAT( '<a target="_new" href="%%WWWROOT%%/user/profile.php', char(63), 'id=', t.id, '">', t.firstname, ' ', t.lastname, '</a>' ) Trainer,
	CONCAT( '<a target="_new" href="%%WWWROOT%%/user/profile.php', char(63), 'id=', u.id, '">', u.firstname, ' ', u.lastname, '</a>' ) Student,
	CONCAT( '<a target="_new" href="%%WWWROOT%%/course/view.php', char(63), 'id=', c.id, '">', c.shortname, '</a>' ) Course,
	CONCAT( '<a target="_new" href="%%WWWROOT%%/mod/assign/view.php', char(63), 'id=', cm.id, '">', a.name, '</a>' ) Assessment,
	FROM_UNIXTIME(s.timemodified) Submit_Time,
	ag.grade Grade,
	FROM_UNIXTIME(Logs.timecreated) Time_Graded,
	CASE
		WHEN c.category IN ( 227, 217, 82, 234, 83, 98, 155, 85, 271, 258, 100, 99, 84, 177, 275, 270, 157, 198, 210, 241, 195, 87, 88, 90, 276, 91, 92, 89, 272, 178, 156, 203, 205, 200, 243, 201, 140, 96, 94, 95, 179, 141, 199, 259, 216, 204, 277, 247, 206, 228, 274, 196, 197, 278, 279, 280, 292, 293, 55, 181 ) THEN 'BSB'
		WHEN c.category IN ( 253, 254, 255, 256, 250, 251, 252, 191, 190, 192, 237, 213, 236 ) THEN 'CHC'
		WHEN c.category IN ( 102, 103, 244, 245, 248, 108, 149, 109, 137, 110, 111, 112, 113, 159, 115, 231, 136, 249, 232, 263, 233, 117, 160, 118, 119, 120, 121, 122, 123, 124, 133, 132, 134, 135, 138, 143, 125, 151, 126, 127, 128, 129, 130, 226, 208, 261, 262, 267, 264, 265, 266, 51 ) THEN 'ICT'
	END Faculty

FROM (
	SELECT log.relateduserid, log.realuserid, log.userid, log.courseid, log.objectid, log.timecreated
	FROM prefix_logstore_standard_log log
	WHERE YEAR(FROM_UNIXTIME(log.timecreated)) = YEAR( DATE_SUB( CURDATE(), INTERVAL 1 MONTH ) )
	AND MONTH(FROM_UNIXTIME(log.timecreated)) = MONTH( DATE_SUB( CURDATE(), INTERVAL 1 MONTH ) )
	AND LOWER(log.action) LIKE '%graded%'
	AND LOWER(log.target) LIKE '%submission%'
) Logs
JOIN prefix_user u ON u.id = Logs.relateduserid
JOIN prefix_user t ON CASE WHEN Logs.realuserid IS NOT NULL THEN t.id = Logs.realuserid ELSE t.id = Logs.userid END
JOIN prefix_course c ON c.id = Logs.courseid
JOIN prefix_assign_grades ag ON ag.id = Logs.objectid
JOIN prefix_assign a ON a.id = ag.assignment
JOIN prefix_course_modules cm ON cm.instance = a.id AND cm.course = c.id
JOIN prefix_assign_submission s ON s.userid = u.id AND s.assignment = a.id AND s.attemptnumber = ag.attemptnumber

WHERE LOWER(a.name) LIKE 'assessment -%'

ORDER BY Faculty ASC, Time_Graded ASC