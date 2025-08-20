// EXEC: cjc %import-path %L %l %f
// EXEC: ./main

import std.database.sql.*
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*
import std.unittest.*
import std.unittest.testmacro.*

main(): Int64 {
    let filterResultTest: OdbcTest = OdbcTest()

    filterResultTest.test001()

    return 0
}

@Test
public class OdbcTest {
    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test_llt")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test_llt(data TIMESTAMP NOT NULL, datanull TIMESTAMP)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test_llt values(?,?)")
        var date = DateTime.of(
            year: 2009,
            month: 11,
            dayOfMonth: 21,
            hour: 13,
            minute: 15,
            second: 35,
            nanosecond: 0,
        )
        prepareStatement.set<DateTime>(0, date)
        prepareStatement.set<Option<DateTime>>(1, Option<DateTime>.None)
        // prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test_llt")
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlOdbcTypeTimeTimestamp", queryResult.columnInfos[0].typeName)
        @Assert("SqlOdbcTypeTimeTimestamp", queryResult.columnInfos[1].typeName)
        @Assert(date, queryResult.get<DateTime>(0))
        let dateTime: ?DateTime = queryResult.getOrNull<DateTime>(1)
        match (dateTime) {
            case Some(v) => @Assert(0, 1)
            case None => @Assert(1, 1)
        }
        queryResult.close()
    }
}
