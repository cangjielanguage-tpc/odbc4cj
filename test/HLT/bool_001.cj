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
        prepareStatement = conn.prepareStatement("create table test(data bool NOT NULL, datanull bool)")
        rowCount = prepareStatement.update()
        @Assert(0, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("insert into test values(?,?)")
        prepareStatement.set<Bool>(0, false)
        prepareStatement.set<Option<Bool>>(1, Option<Bool>.None)
        // prepareStatement.setNull(1)
        rowCount = prepareStatement.update()
        @Assert(1, rowCount.rowCount)
        prepareStatement = conn.prepareStatement("select * from test")
        var queryResult = prepareStatement.query()
        let a = queryResult.next()
        @Assert(true, a)
        @Assert("SqlInt8", queryResult.columnInfos[0].typeName)
        @Assert("SqlInt8", queryResult.columnInfos[1].typeName)
        @Assert(0, queryResult.get<Int8>(0))
        @Assert(None, queryResult.getOrNull<Int8>(1))
        queryResult.close()
    }
}
