//3rd_party_lib:odbc4cj/build/odbc4cj

import std.database.sql.*
import std.io.*
import std.time.*
import std.regex.*
import odbc4cj.*

@Test
public class OdbcTest {
    init() {
    }

    @TestCase
    public func test001(): Unit {
        var driver = OdbcDriver()
        var database = driver.open("DATABASE=mysql;UID=root;PWD=123")
        var conn = database.connect()
        var prepareStatement = conn.prepareStatement("drop table if exists test")
        var rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("create table test(id int NOT NULL, data varchar(20) NOT NULL)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        prepareStatement.set<Int32>(0, 1)
        prepareStatement.set<String>(1, "abc")
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test where id = ?")
        prepareStatement.set<Int32>(0, 1)
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlInt32", queryResult.columnInfos[0].typeName)
        @Assert("SqlString", queryResult.columnInfos[1].typeName)
        @Assert(1, queryResult.get<Int32>(0))
        @Assert("abc", queryResult.get<String>(1))
        queryResult.close()
    }
}
